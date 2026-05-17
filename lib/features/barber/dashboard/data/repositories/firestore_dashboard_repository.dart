import 'package:cloud_firestore/cloud_firestore.dart';

import '/../../../core/error/failures.dart';
import '/../../../core/usecases/usecase.dart';
import '../../../../bookings/data/models/booking_model.dart';
import '../../../../bookings/domain/entities/booking.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/daily_summary.dart';
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
              incomePreviousDay: 0,
              completedAppointments: 0,
              totalAppointments: 0,
            ),
            weekly: WeeklyPerformance(
              dailyValues: [0, 0, 0, 0, 0, 0, 0],
              todayIndex: 0,
            ),
            todayAppointments: [],
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
        start: today,
        end: tomorrow,
      );
      final yesterdayBookings = await _bookingRange(
        barbershopId: barbershopId,
        start: yesterday,
        end: today,
      );
      final weekBookings = await _bookingRange(
        barbershopId: barbershopId,
        start: weekStart,
        end: weekEnd,
      );

      final completedToday = todayBookings
          .where(
            (booking) => booking.status == AppointmentBookingStatus.completed,
          )
          .toList();

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

      return Ok(
        DashboardData(
          summary: summary,
          weekly: WeeklyPerformance(
            dailyValues: normalized,
            todayIndex: now.weekday - 1,
          ),
          todayAppointments: todayBookings.map(_toAppointment).toList(),
        ),
      );
    } catch (_) {
      return const Fail(UnknownFailure('No se pudo cargar el panel'));
    }
  }

  Future<List<Booking>> _bookingRange({
    required String barbershopId,
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
    return snapshot.docs.map(BookingModel.fromDocument).toList();
  }

  Appointment _toAppointment(Booking booking) {
    return Appointment(
      id: booking.id,
      clientName: booking.clientSnapshot.name,
      serviceName: booking.serviceSnapshot.name,
      startTime: booking.slotStart,
      status: switch (booking.status) {
        AppointmentBookingStatus.inProgress => AppointmentStatus.inProgress,
        AppointmentBookingStatus.completed => AppointmentStatus.completed,
        _ => AppointmentStatus.upcoming,
      },
    );
  }
}
