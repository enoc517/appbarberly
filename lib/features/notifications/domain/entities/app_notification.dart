enum AppNotificationType {
  bookingCreated,
  bookingRescheduled,
  bookingReminder,
  bookingCancelled,
  lateCancellationPenalty,
  penaltyResolved,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.recipientRole,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.bookingId,
    this.barbershopId,
    this.penaltyId,
    this.readAt,
  });

  final String id;
  final String recipientId;
  final String recipientRole;
  final AppNotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? bookingId;
  final String? barbershopId;
  final String? penaltyId;
  final DateTime? readAt;

  bool get isRead => readAt != null;
}
