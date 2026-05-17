enum MembershipRole { owner, member }

class BarberMember {
  final String barberId;
  final String barberName;
  final String barberAvatarUrl;
  final MembershipRole role;
  final DateTime joinedAt;

  const BarberMember({
    required this.barberId,
    required this.barberName,
    required this.barberAvatarUrl,
    required this.role,
    required this.joinedAt,
  });
}
