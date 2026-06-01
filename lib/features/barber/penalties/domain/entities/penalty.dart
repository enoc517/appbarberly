enum PenaltyStatus { pending, paid, waived }

class Penalty {
  const Penalty({
    required this.id,
    required this.bookingId,
    required this.barbershopId,
    required this.barberId,
    required this.clientId,
    required this.clientName,
    required this.serviceName,
    required this.appointmentStart,
    required this.servicePrice,
    required this.penaltyAmount,
    required this.penaltyPercent,
    required this.status,
    this.clientAvatarUrl,
    this.createdAt,
    this.resolvedAt,
  });

  final String id;
  final String bookingId;
  final String barbershopId;
  final String barberId;
  final String clientId;
  final String clientName;
  final String? clientAvatarUrl;
  final String serviceName;
  final DateTime appointmentStart;
  final double servicePrice;
  final double penaltyAmount;
  final int penaltyPercent;
  final PenaltyStatus status;
  final DateTime? createdAt;
  final DateTime? resolvedAt;
}
