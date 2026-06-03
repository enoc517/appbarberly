import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/booking.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../models/booking_model.dart';

class FirestoreBookingsRepository implements BookingsRepository {
  FirestoreBookingsRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('bookings');

  @override
  Future<String> createBooking(BookingDraft draft) async {
    final bookingRef = _bookings.doc();
    final userRef = _db.collection('users').doc(draft.clientId);
    final slotRef = draft.slotPath == null ? null : _db.doc(draft.slotPath!);

    final sameDaySnapshot = await _bookings
        .where('barbershopId', isEqualTo: draft.barbershopId)
        .where('dateKey', isEqualTo: draft.dateKey)
        .orderBy('slotStart')
        .get();
    final hasConflict = sameDaySnapshot.docs.any((doc) {
      final data = doc.data();
      if (data['barberId'] != draft.barberId) return false;
      final status = _bookingStatus(data['status'] as String?);
      if (!status.isActive) return false;
      final existingStart = _dateTime(data['slotStart']);
      final existingEnd = _dateTime(data['slotEnd']);
      return _overlaps(
        draft.slotStart,
        draft.slotEnd,
        existingStart,
        existingEnd,
      );
    });

    if (hasConflict) {
      throw StateError('El horario ya no está disponible.');
    }

    await _db.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final userData = userSnapshot.data() ?? <String, dynamic>{};
      final activeBookingId = userData['activeBookingId'] as String?;
      final activeBookingStatus = userData['activeBookingStatus'] as String?;
      final hasActiveBooking =
          activeBookingId != null &&
          _activeStatusNames.contains(activeBookingStatus);

      if (hasActiveBooking) {
        throw StateError('El cliente ya tiene una cita activa.');
      }

      if (slotRef != null) {
        final slotSnapshot = await transaction.get(slotRef);
        final slotData = slotSnapshot.data();
        if (slotData == null || slotData['status'] != 'available') {
          throw StateError('El horario ya no está disponible.');
        }
        transaction.update(slotRef, {
          'status': 'booked',
          'bookingId': bookingRef.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.set(bookingRef, {
        'clientId': draft.clientId,
        'barberId': draft.barberId,
        'barbershopId': draft.barbershopId,
        'serviceId': draft.serviceId,
        'dateKey': draft.dateKey,
        'slotStart': Timestamp.fromDate(draft.slotStart),
        'slotEnd': Timestamp.fromDate(draft.slotEnd),
        'status': AppointmentBookingStatus.confirmed.name,
        'price': draft.price,
        'durationMinutes': draft.durationMinutes,
        'clientSnapshot': _snapshotToMap(draft.clientSnapshot),
        'barberSnapshot': _snapshotToMap(draft.barberSnapshot),
        'shopSnapshot': _snapshotToMap(draft.shopSnapshot),
        'serviceSnapshot': _snapshotToMap(draft.serviceSnapshot),
        'slotPath': draft.slotPath,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(userRef, {
        'activeBookingId': bookingRef.id,
        'activeBookingStatus': AppointmentBookingStatus.confirmed.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    return bookingRef.id;
  }

  @override
  Future<void> cancelBooking({
    required String bookingId,
    required String clientId,
    required BookingCancellationActor cancelledBy,
  }) async {
    await _finishBooking(
      bookingId: bookingId,
      clientId: clientId,
      status: AppointmentBookingStatus.cancelled,
      cancelledBy: cancelledBy,
    );
  }

  @override
  Future<void> completeBooking({
    required String bookingId,
    required String clientId,
  }) async {
    await _finishBooking(
      bookingId: bookingId,
      clientId: clientId,
      status: AppointmentBookingStatus.completed,
      cancelledBy: null,
    );
  }

  Future<void> _finishBooking({
    required String bookingId,
    required String clientId,
    required AppointmentBookingStatus status,
    required BookingCancellationActor? cancelledBy,
  }) async {
    final bookingRef = _bookings.doc(bookingId);
    final userRef = _db.collection('users').doc(clientId);
    final penaltyRef = _db.collection('penalties').doc();
    final cancellationNotificationRef = _db.collection('notifications').doc();
    final penaltyNotificationRef = _db.collection('notifications').doc();

    await _db.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingRef);
      final bookingData = bookingSnapshot.data();
      if (bookingData == null) return;

      final cancellationData = <String, dynamic>{};
      if (status == AppointmentBookingStatus.cancelled && cancelledBy != null) {
        cancellationData.addAll({
          'cancelledBy': cancelledBy.name,
          'cancelledAt': FieldValue.serverTimestamp(),
        });
      }

      if (status == AppointmentBookingStatus.cancelled && cancelledBy != null) {
        final recipientId = cancelledBy == BookingCancellationActor.client
            ? bookingData['barberId'] as String? ?? ''
            : bookingData['clientId'] as String? ?? clientId;
        final recipientRole = cancelledBy == BookingCancellationActor.client
            ? 'barber'
            : 'client';
        if (recipientId.isNotEmpty) {
          transaction.set(cancellationNotificationRef, {
            'recipientId': recipientId,
            'recipientRole': recipientRole,
            'type': 'bookingCancelled',
            'title': 'Cita cancelada',
            'body': _cancellationNotificationBody(bookingData, cancelledBy),
            'bookingId': bookingRef.id,
            'barbershopId': bookingData['barbershopId'] as String? ?? '',
            'penaltyId': null,
            'readAt': null,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'data': {'cancelledBy': cancelledBy.name},
          });
        }
      }

      transaction.update(bookingRef, {
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
        ...cancellationData,
      });

      if (status == AppointmentBookingStatus.cancelled &&
          cancelledBy == BookingCancellationActor.client) {
        final slotStart = _dateTime(bookingData['slotStart']);
        final price = (bookingData['price'] as num?)?.toDouble() ?? 0;
        final shouldApplyPenalty =
            slotStart.difference(DateTime.now()) < const Duration(hours: 1);

        if (shouldApplyPenalty && price > 0) {
          final penaltyAmount = price * 0.5;
          transaction.set(penaltyRef, {
            'bookingId': bookingRef.id,
            'barbershopId': bookingData['barbershopId'] as String? ?? '',
            'barberId': bookingData['barberId'] as String? ?? '',
            'clientId': bookingData['clientId'] as String? ?? clientId,
            'clientSnapshot': bookingData['clientSnapshot'],
            'serviceSnapshot': bookingData['serviceSnapshot'],
            'shopSnapshot': bookingData['shopSnapshot'],
            'appointmentStart': bookingData['slotStart'],
            'servicePrice': price,
            'penaltyPercent': 50,
            'penaltyAmount': penaltyAmount,
            'status': 'pending',
            'reason': 'lateClientCancellation',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'resolvedAt': null,
          });

          transaction.update(bookingRef, {
            'penaltyApplied': true,
            'penaltyAmount': penaltyAmount,
            'penaltyStatus': 'pending',
            'penaltyId': penaltyRef.id,
          });

          final barberId = bookingData['barberId'] as String? ?? '';
          if (barberId.isNotEmpty) {
            transaction.set(penaltyNotificationRef, {
              'recipientId': barberId,
              'recipientRole': 'barber',
              'type': 'lateCancellationPenalty',
              'title': 'Penalización pendiente',
              'body': _penaltyNotificationBody(bookingData, penaltyAmount),
              'bookingId': bookingRef.id,
              'barbershopId': bookingData['barbershopId'] as String? ?? '',
              'penaltyId': penaltyRef.id,
              'readAt': null,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'data': {'penaltyAmount': penaltyAmount, 'penaltyPercent': 50},
            });
          }
        } else {
          transaction.update(bookingRef, {
            'penaltyApplied': false,
            'penaltyAmount': 0,
            'penaltyStatus': null,
          });
        }
      }

      final slotPath = bookingData['slotPath'] as String?;
      if (status == AppointmentBookingStatus.cancelled &&
          slotPath != null &&
          slotPath.isNotEmpty) {
        transaction.update(_db.doc(slotPath), {
          'status': 'available',
          'bookingId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.set(userRef, {
        'activeBookingId': null,
        'activeBookingStatus': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  @override
  Stream<List<Booking>> watchClientBookings(String clientId) {
    return _bookings
        .where('clientId', isEqualTo: clientId)
        .orderBy('slotStart', descending: true)
        .snapshots()
        .map(_toBookings);
  }

  @override
  Stream<List<Booking>> watchBarberAgenda({
    required String barbershopId,
    required String dateKey,
  }) {
    return _bookings
        .where('barbershopId', isEqualTo: barbershopId)
        .where('dateKey', isEqualTo: dateKey)
        .orderBy('slotStart')
        .snapshots()
        .map(_toBookings);
  }

  @override
  Stream<List<Booking>> watchBarbershopBookings({
    required String barbershopId,
    required DateTime start,
    required DateTime end,
  }) {
    return _bookings
        .where('barbershopId', isEqualTo: barbershopId)
        .where('slotStart', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('slotStart', isLessThan: Timestamp.fromDate(end))
        .orderBy('slotStart')
        .snapshots()
        .map(_toBookings);
  }

  List<Booking> _toBookings(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs.map(BookingModel.fromDocument).toList();
  }

  Map<String, dynamic> _snapshotToMap(BookingSnapshot snapshot) {
    return {'name': snapshot.name, 'imageUrl': snapshot.imageUrl};
  }

  static DateTime _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static AppointmentBookingStatus _bookingStatus(String? value) {
    return AppointmentBookingStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => AppointmentBookingStatus.cancelled,
    );
  }

  static bool _overlaps(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
  }

  static String _cancellationNotificationBody(
    Map<String, dynamic> bookingData,
    BookingCancellationActor cancelledBy,
  ) {
    final clientName = _snapshotName(
      bookingData['clientSnapshot'],
      'El cliente',
    );
    final barberName = _snapshotName(
      bookingData['barberSnapshot'],
      'El barbero',
    );
    final serviceName = _snapshotName(
      bookingData['serviceSnapshot'],
      'la cita',
    );
    if (cancelledBy == BookingCancellationActor.client) {
      return '$clientName canceló $serviceName.';
    }
    return '$barberName canceló $serviceName.';
  }

  static String _penaltyNotificationBody(
    Map<String, dynamic> bookingData,
    double penaltyAmount,
  ) {
    final clientName = _snapshotName(
      bookingData['clientSnapshot'],
      'El cliente',
    );
    final amount = penaltyAmount.toStringAsFixed(0);
    return '$clientName canceló tarde y debe una penalización de \$$amount.';
  }

  static String _snapshotName(Object? value, String fallback) {
    if (value is Map<String, dynamic>) {
      final name = value['name'] as String?;
      if (name != null && name.trim().isNotEmpty) return name.trim();
    }
    return fallback;
  }

  static const _activeStatusNames = {'pending', 'confirmed', 'inProgress'};
}
