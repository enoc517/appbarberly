enum MembershipRequestStatus { pending, approved, rejected }

class MembershipRequest {
  final String id;
  final String barberId;
  final String barberName;
  final String barberEmail;
  final String barberAvatarUrl;
  final String barbershopId;
  final String barbershopName;
  final MembershipRequestStatus status;
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  const MembershipRequest({
    required this.id,
    required this.barberId,
    required this.barberName,
    required this.barberEmail,
    required this.barberAvatarUrl,
    required this.barbershopId,
    required this.barbershopName,
    required this.status,
    required this.requestedAt,
    this.reviewedAt,
    this.reviewedBy,
  });
}
