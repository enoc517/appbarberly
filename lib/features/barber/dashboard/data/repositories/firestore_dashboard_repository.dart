import 'package:cloud_firestore/cloud_firestore.dart';

import '/../../../core/error/failures.dart';
import '/../../../core/usecases/usecase.dart';
import '../../../../bookings/data/models/booking_model.dart';
import '../../../../bookings/domain/entities/booking.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/daily_summary.dart';
import '../../domain/entities/dashboard_overview.dart';
import '../../domain/entities/weekly_performance.dart';
import '../../domain/repositories/dashboard_repository.dart';

class FirestoreDashboardRepository implements DashboardRepository {
  FirestoreDashboardRepository({
    required FirebaseFirestore firestore,
    required String userId,
  }) : _db = firestore,
       _userId = userId;

  final FirebaseFirestore _db;
  final String _userId;

  @override
  Future<Result<DashboardData>> getDashboardData(String barberId) async {
    try {
      if (_userId.isEmpty) {
        return const Fail(UnknownFailure('No hay usuario autenticado'));
      }

      final userDoc = await _db.collection('users').doc(_userId).get();
      final userData = userDoc.data() ?? <String, dynamic>{};
      final barbershopId = userData['barbershopId'] as String?;

      if (barbershopId == null || barbershopId.isEmpty) {
        return Ok(
          DashboardData(
            summary: const DailySummary(
              incomeToday: 0,
              estimatedIncomeToday: 0,
              incomePreviousDay: 0,
              completedAppointments: 0,
              totalAppointments: 0,
            ),
            weekly: WeeklyPerformance(
              dailyValues: [0, 0, 0, 0, 0, 0, 0],
              todayIndex: 0,
            ),
            todayAppointments: [],
            nextAppointment: null,
            weekOverview: const BarberWeeklyOverview(
              totalAppointments: 0,
              completedAppointments: 0,
              cancelledAppointments: 0,
              upcomingAppointments: 0,
              estimatedIncome: 0,
            ),
            topServices: const [],
            upcomingBlockedHours: const [],
          ),
        );
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final yesterday = today.subtract(const Duration(days: 1));
      final weekStart = today.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));

      final todayBookings = await _bookingRange(
        barbershopId: barbershopId,
        barberId: barberId,
        start: today,
        end: tomorrow,
      );
      final yesterdayBookings = await _bookingRange(
        barbershopId: barbershopId,
        barberId: barberId,
        start: yesterday,
        end: today,
      );
      final weekBookings = await _bookingRange(
        barbershopId: barbershopId,
        barberId: barberId,
        start: weekStart,
        end: weekEnd,
      );
      final futureBookings = await _bookingRange(
        barbershopId: barbershopId,
        barberId: barberId,
        start: now,
        end: weekEnd,
      );
      final blockedSlots = await _safeBlockedSlotsRange(
        barbershopId: barbershopId,
        barberId: barberId,
        start: now,
        end: weekEnd,
      );

      final completedToday = todayBookings
          .where(
            (booking) => booking.status == AppointmentBookingStatus.completed,
          )
          .toList();
      final estimatedToday = todayBookings
          .where(
            (booking) => booking.status != AppointmentBookingStatus.cancelled,
          )
          .fold<double>(0, (total, booking) => total + booking.price);

      final summary = DailySummary(
        incomeToday: completedToday.fold<double>(
          0,
          (total, booking) => total + booking.price,
        ),
        incomePreviousDay: yesterdayBookings
            .where(
              (booking) => booking.status == AppointmentBookingStatus.completed,
            )
            .fold<double>(0, (total, booking) => total + booking.price),
        completedAppointments: completedToday.length,
        totalAppointments: todayBookings.length,
        estimatedIncomeToday: estimatedToday,
      );

      final dailyCounts = List<double>.filled(7, 0);
      for (final booking in weekBookings) {
        final index = booking.slotStart.weekday - 1;
        dailyCounts[index] += 1;
      }
      final maxCount = dailyCounts.fold<double>(0, (a, b) => a > b ? a : b);
      final normalized = maxCount == 0
          ? dailyCounts
          : dailyCounts.map((value) => value / maxCount).toList();

      final cancelledWeek = weekBookings
          .where(
            (booking) => booking.status == AppointmentBookingStatus.cancelled,
          )
          .length;
      final completedWeek = weekBookings
          .where(
            (booking) => booking.status == AppointmentBookingStatus.completed,
          )
          .length;
      final upcomingWeek = weekBookings
          .where((booking) => booking.status.isActive)
          .length;
      final estimatedWeekIncome = weekBookings
          .where(
            (booking) => booking.status != AppointmentBookingStatus.cancelled,
          )
          .fold<double>(0, (total, booking) => total + booking.price);

      final serviceTotals = <String, _ServiceAccumulator>{};
      for (final booking in weekBookings) {
        if (booking.status != AppointmentBookingStatus.completed) continue;
        final key = booking.serviceId;
        final accumulator = serviceTotals.putIfAbsent(
          key,
          () => _ServiceAccumulator(name: booking.serviceSnapshot.name),
        );
        accumulator.count += 1;
        accumulator.income += booking.price;
      }

      final topServices =
          serviceTotals.values
              .map(
                (entry) => ServicePerformance(
                  serviceName: entry.name,
                  count: entry.count,
                  estimatedIncome: entry.income,
                ),
              )
              .toList()
            ..sort((a, b) {
              final compare = b.count.compareTo(a.count);
              if (compare != 0) return compare;
              return b.estimatedIncome.compareTo(a.estimatedIncome);
            });

      final nextBooking =
          futureBookings
              .where(
                (booking) =>
                    booking.status != AppointmentBookingStatus.cancelled,
              )
              .toList()
            ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
      final nextAppointment = nextBooking.isEmpty
          ? null
          : _toAppointment(nextBooking.first);

      return Ok(
        DashboardData(
          summary: summary,
          weekly: WeeklyPerformance(
            dailyValues: normalized,
            todayIndex: now.weekday - 1,
          ),
          todayAppointments: todayBookings.map(_toAppointment).toList(),
          nextAppointment: nextAppointment,
          weekOverview: BarberWeeklyOverview(
            totalAppointments: weekBookings.length,
            completedAppointments: completedWeek,
            cancelledAppointments: cancelledWeek,
            upcomingAppointments: upcomingWeek,
            estimatedIncome: estimatedWeekIncome,
          ),
          topServices: topServices.take(3).toList(),
          upcomingBlockedHours: blockedSlots,
        ),
      );
    } catch (_) {
      return const Fail(UnknownFailure('No se pudo cargar el panel'));
    }
  }

  Future<List<Booking>> _bookingRange({
    required String barbershopId,
    required String barberId,
    required DateTime start,
    required DateTime end,
  }) async {
    final snapshot = await _db
        .collection('bookings')
        .where('barbershopId', isEqualTo: barbershopId)
        .where('slotStart', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('slotStart', isLessThan: Timestamp.fromDate(end))
        .orderBy('slotStart')
        .get();
    return snapshot.docs
        .map(BookingModel.fromDocument)
        .where((booking) => booking.barberId == barberId)
        .toList();
  }

  Future<List<BlockedTimeBlock>> _blockedSlotsRange({
    required String barbershopId,
    required String barberId,
    required DateTime start,
    required DateTime end,
  }) async {
    final snapshot = await _db
        .collection('barbershops')
        .doc(barbershopId)
        .collection('barbers')
        .doc(barberId)
        .collection('blocked_slots')
        .where('isActive', isEqualTo: true)
        .where('start', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('start', isLessThan: Timestamp.fromDate(end))
        .orderBy('start')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return BlockedTimeBlock(
        start: _dateTime(data['start']),
        end: _dateTime(data['end']),
        reason: data['reason'] as String? ?? '',
      );
    }).toList();
  }

  Future<List<BlockedTimeBlock>> _safeBlockedSlotsRange({
    required String barbershopId,
    required String barberId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      return await _blockedSlotsRange(
        barbershopId: barbershopId,
        barberId: barberId,
        start: start,
        end: end,
      );
    } catch (_) {
      return const [];
    }
  }

  Appointment _toAppointment(Booking booking) {
    return Appointment(
      id: booking.id,
      clientName: booking.clientSnapshot.name,
      clientAvatarUrl: booking.clientSnapshot.imageUrl,
      serviceName: booking.serviceSnapshot.name,
      startTime: booking.slotStart,
      status: switch (booking.status) {
        AppointmentBookingStatus.inProgress => AppointmentStatus.inProgress,
        AppointmentBookingStatus.completed => AppointmentStatus.completed,
        _ => AppointmentStatus.upcoming,
      },
    );
  }

  static DateTime _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class _ServiceAccumulator {
  _ServiceAccumulator({required this.name});

  final String name;
  int count = 0;
  double income = 0;
}
