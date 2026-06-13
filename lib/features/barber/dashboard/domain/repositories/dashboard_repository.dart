import '../../../../../core/usecases/usecase.dart';
import '../entities/appointment.dart';
import '../entities/daily_summary.dart';
import '../entities/dashboard_overview.dart';
import '../entities/weekly_performance.dart';

class DashboardData {
  final DailySummary summary;
  final WeeklyPerformance weekly;
  final List<Appointment> todayAppointments;
  final Appointment? nextAppointment;
  final BarberWeeklyOverview weekOverview;
  final List<ServicePerformance> topServices;
  final List<BlockedTimeBlock> upcomingBlockedHours;

  const DashboardData({
    required this.summary,
    required this.weekly,
    required this.todayAppointments,
    required this.nextAppointment,
    required this.weekOverview,
    required this.topServices,
    required this.upcomingBlockedHours,
  });
}

abstract class DashboardRepository {
  Future<Result<DashboardData>> getDashboardData(String barberId);
}
