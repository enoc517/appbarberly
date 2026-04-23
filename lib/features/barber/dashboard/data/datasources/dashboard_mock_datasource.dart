import '../../domain/entities/appointment.dart';
import '../../domain/entities/daily_summary.dart';
import '../../domain/entities/weekly_performance.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardMockDataSource {
  Future<DashboardData> fetch(String barberId) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return DashboardData(
      summary: const DailySummary(
        incomeToday: 420.50,
        incomePreviousDay: 375.45,
        completedAppointments: 8,
        totalAppointments: 12,
      ),
      weekly: WeeklyPerformance(
        dailyValues: const [0.35, 0.45, 0.65, 0.50, 0.55, 0.40, 0.90],
        todayIndex: (now.weekday - 1).clamp(0, 6),
      ),
      todayAppointments: [
        Appointment(
          id: '1',
          clientName: 'Carlos Méndez',
          serviceName: 'Corte Premium + Barba',
          startTime: today.add(const Duration(hours: 14)),
          status: AppointmentStatus.upcoming,
        ),
        Appointment(
          id: '2',
          clientName: 'Javier Ruiz',
          serviceName: 'Perfilado de Cejas',
          startTime: today.add(const Duration(hours: 15, minutes: 30)),
          status: AppointmentStatus.inProgress,
        ),
        Appointment(
          id: '3',
          clientName: 'Ricardo Soto',
          serviceName: 'Corte Clásico',
          startTime: today.add(const Duration(hours: 17)),
          status: AppointmentStatus.upcoming,
        ),
        Appointment(
          id: '4',
          clientName: 'Andrés Villa',
          serviceName: 'Tratamiento Facial',
          startTime: today.add(const Duration(hours: 18, minutes: 30)),
          status: AppointmentStatus.upcoming,
        ),
      ],
    );
  }
}