enum AppointmentStatus { upcoming, inProgress, completed }

class Appointment {
  final String id;
  final String clientName;
  final String? clientAvatarUrl;
  final String serviceName;
  final DateTime startTime;
  final AppointmentStatus status;

  const Appointment({
    required this.id,
    required this.clientName,
    this.clientAvatarUrl,
    required this.serviceName,
    required this.startTime,
    required this.status,
  });

  bool get isNow => status == AppointmentStatus.inProgress;
}