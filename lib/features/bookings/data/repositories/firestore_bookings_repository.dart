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
  }) async {
    final bookingRef = _bookings.doc(bookingId);
    final userRef = _db.collection('users').doc(clientId);

    await _db.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingRef);
      final bookingData = bookingSnapshot.data();
      if (bookingData == null) return;

      transaction.update(bookingRef, {
        'status': AppointmentBookingStatus.cancelled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final slotPath = bookingData['slotPath'] as String?;
      if (slotPath != null && slotPath.isNotEmpty) {
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

  static const _activeStatusNames = {'pending', 'confirmed', 'inProgress'};
}
