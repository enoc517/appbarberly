import '../../domain/repositories/dashboard_repository.dart';

sealed class DashboardState {
  const DashboardState();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardData data;
  const DashboardLoaded(this.data);
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
}