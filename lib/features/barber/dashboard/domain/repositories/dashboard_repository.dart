import '../../../../../core/usecases/usecase.dart';
import '../entities/appointment.dart';
import '../entities/daily_summary.dart';
import '../entities/weekly_performance.dart';

class DashboardData {
  final DailySummary summary;
  final WeeklyPerformance weekly;
  final List<Appointment> todayAppointments;

  const DashboardData({
    required this.summary,
    required this.weekly,
    required this.todayAppointments,
  });
}

abstract class DashboardRepository {
  Future<Result<DashboardData>> getDashboardData(String barberId);
}