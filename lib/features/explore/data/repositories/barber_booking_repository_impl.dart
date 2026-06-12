import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../bookings/data/repositories/firestore_bookings_repository.dart';
import '../../../bookings/domain/entities/booking.dart';
import '../../../bookings/data/models/booking_model.dart';
import '../../../barber/services/domain/entities/barber_schedule.dart';
import '../../domain/repositories/barber_booking_repository.dart';

class BarberBookingRepositoryImpl implements BarberBookingRepository {
  BarberBookingRepositoryImpl({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<BarberBookingData> loadBarberData(
    String shopId,
    String barberId,
  ) async {
    final memberDoc = await _db
        .collection('barbershops')
        .doc(shopId)
        .collection('members')
        .doc(barberId)
        .get();

    final barberName = memberDoc.data()?['barberName'] as String? ?? 'Barbero';
    final barberAvatarUrl = await _resolveBarberAvatarUrl(memberDoc, barberId);

    final servicesSnapshot = await _db
        .collection('barbershops')
        .doc(shopId)
        .collection('barbers')
        .doc(barberId)
        .collection('services')
        .where('isActive', isEqualTo: true)
        .get();

    final scheduleSnapshot = await _db
        .collection('barbershops')
        .doc(shopId)
        .collection('barbers')
        .doc(barberId)
        .collection('schedule')
        .get();

    final services = servicesSnapshot.docs
        .map((d) => {'id': d.id, ...d.data()})
        .toList();

    final schedule = <int, BarberSchedule>{};
    for (final doc in scheduleSnapshot.docs) {
      final data = doc.data();
      if (data['isActive'] == true) {
        schedule[data['dayOfWeek'] as int] = BarberSchedule(
          id: doc.id,
          dayOfWeek: data['dayOfWeek'] as int? ?? 0,
          startTime: data['startTime'] as String? ?? '',
          endTime: data['endTime'] as String? ?? '',
          isActive: true,
        );
      }
    }

    return BarberBookingData(
      barberName: barberName,
      barberAvatarUrl: barberAvatarUrl,
      services: services,
      schedule: schedule,
    );
  }

  @override
  Future<List<String>> loadAvailableTimeSlots({
    required String shopId,
    required String barberId,
    required DateTime day,
    required int durationMinutes,
    String? excludeBookingId,
  }) async {
    final scheduleDoc = await _db
        .collection('barbershops')
        .doc(shopId)
        .collection('barbers')
        .doc(barberId)
        .collection('schedule')
        .doc('day_${day.weekday}')
        .get();

    final scheduleData = scheduleDoc.data();
    if (scheduleData == null || scheduleData['isActive'] != true) {
      return const [];
    }

    final startTime = scheduleData['startTime'] as String? ?? '';
    final endTime = scheduleData['endTime'] as String? ?? '';
    final start = _timeOfDay(day, startTime);
    final end = _timeOfDay(day, endTime);

    if (!end.isAfter(start)) return const [];

    final slotStep = const Duration(minutes: 30);
    var candidateStart = start;

    final now = DateTime.now();
    if (_isSameDay(day, now)) {
      final nextSlotStart = _ceilToSlot(now, slotStep);
      if (nextSlotStart.isAfter(candidateStart)) {
        candidateStart = nextSlotStart;
      }
    }

    final dateKey = _dateKey(day);
    final bookingsSnapshot = await _db
        .collection('bookings')
        .where('barbershopId', isEqualTo: shopId)
        .where('barberId', isEqualTo: barberId)
        .where('dateKey', isEqualTo: dateKey)
        .orderBy('slotStart')
        .get();

    final activeBookings = bookingsSnapshot.docs
        .map(BookingModel.fromDocument)
        .where(
          (booking) =>
              booking.status.isActive && booking.id != excludeBookingId,
        )
        .toList();

    final blockedSlotsSnapshot = await _db
        .collection('barbershops')
        .doc(shopId)
        .collection('barbers')
        .doc(barberId)
        .collection('blocked_slots')
        .where('dateKey', isEqualTo: dateKey)
        .get();

    final blockedSlots = blockedSlotsSnapshot.docs
        .map((doc) => doc.data())
        .where((data) => data['isActive'] == true)
        .map(
          (data) => (
            start: _dateTime(data['start']),
            end: _dateTime(data['end']),
          ),
        )
        .toList(growable: false);

    final candidates = <String>[];

    while (candidateStart
            .add(Duration(minutes: durationMinutes))
            .isBefore(end) ||
        candidateStart
            .add(Duration(minutes: durationMinutes))
            .isAtSameMomentAs(end)) {
      final candidateEnd = candidateStart.add(
        Duration(minutes: durationMinutes),
      );
      final overlaps = activeBookings.any(
        (booking) => _overlaps(
          candidateStart,
          candidateEnd,
          booking.slotStart,
          booking.slotEnd,
        ),
      );
      final blocked = blockedSlots.any(
        (slot) => _overlaps(
          candidateStart,
          candidateEnd,
          slot.start,
          slot.end,
        ),
      );
      if (!overlaps && !blocked) {
        candidates.add(_formatTime(candidateStart));
      }
      candidateStart = candidateStart.add(slotStep);
    }

    return candidates;
  }

  @override
  Future<String> getClientName(String clientId) async {
    final clientDoc = await _db.collection('users').doc(clientId).get();
    return clientDoc.data()?['fullName'] as String? ?? 'Cliente';
  }

  @override
  Future<String> getShopName(String shopId) async {
    final shopDoc = await _db.collection('barbershops').doc(shopId).get();
    return shopDoc.data()?['name'] as String? ?? '';
  }

  @override
  Future<void> createBooking(BookingDraft draft) async {
    final repository = FirestoreBookingsRepository(firestore: _db);
    await repository.createBooking(draft);
  }

  @override
  Future<void> rescheduleBooking({
    required String bookingId,
    required BookingDraft draft,
  }) async {
    final repository = FirestoreBookingsRepository(firestore: _db);
    await repository.rescheduleBooking(bookingId: bookingId, draft: draft);
  }

  static String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static DateTime _timeOfDay(DateTime day, String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  static DateTime _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static bool _overlaps(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime _ceilToSlot(DateTime time, Duration slotStep) {
    final truncated = DateTime(time.year, time.month, time.day, time.hour, time.minute);
    final remainder = time.minute % slotStep.inMinutes;
    if (remainder == 0 && time.second == 0 && time.millisecond == 0 && time.microsecond == 0) {
      return truncated;
    }

    return truncated.add(Duration(minutes: slotStep.inMinutes - remainder));
  }

  Future<String?> _resolveBarberAvatarUrl(
    DocumentSnapshot<Map<String, dynamic>> memberDoc,
    String barberId,
  ) async {
    final memberData = memberDoc.data() ?? <String, dynamic>{};
    final memberAvatarUrl = memberData['barberAvatarUrl'] as String?;
    if (memberAvatarUrl != null && memberAvatarUrl.isNotEmpty) {
      return memberAvatarUrl;
    }

    final userDoc = await _db.collection('users').doc(barberId).get();
    final userAvatarUrl = userDoc.data()?['profileImageUrl'] as String?;
    if (userAvatarUrl != null && userAvatarUrl.isNotEmpty) {
      return userAvatarUrl;
    }

    return null;
  }
}
