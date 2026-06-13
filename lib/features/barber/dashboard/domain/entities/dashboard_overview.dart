import 'appointment.dart';

class BarberWeeklyOverview {
  final int totalAppointments;
  final int completedAppointments;
  final int cancelledAppointments;
  final int upcomingAppointments;
  final double estimatedIncome;

  const BarberWeeklyOverview({
    required this.totalAppointments,
    required this.completedAppointments,
    required this.cancelledAppointments,
    required this.upcomingAppointments,
    required this.estimatedIncome,
  });
}

class ServicePerformance {
  final String serviceName;
  final int count;
  final double estimatedIncome;

  const ServicePerformance({
    required this.serviceName,
    required this.count,
    required this.estimatedIncome,
  });
}

class BlockedTimeBlock {
  final DateTime start;
  final DateTime end;
  final String reason;

  const BlockedTimeBlock({
    required this.start,
    required this.end,
    required this.reason,
  });

  Duration get duration => end.difference(start);
}

class DashboardNextAppointment extends Appointment {
  const DashboardNextAppointment({
    required super.id,
    required super.clientName,
    super.clientAvatarUrl,
    required super.serviceName,
    required super.startTime,
    required super.status,
  });
}
