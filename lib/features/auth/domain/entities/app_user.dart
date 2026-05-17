enum UserRole { client, barber }

enum ProfessionalStatus { none, pending, approved, rejected }

class AppUser {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final UserRole role;
  final bool isProfessional;
  final ProfessionalStatus professionalStatus;
  final bool emailVerified;
  final String? barbershopId;
  final String? activeBookingId;
  final String? activeBookingStatus;

  const AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    required this.role,
    required this.isProfessional,
    required this.professionalStatus,
    required this.emailVerified,
    this.barbershopId,
    this.activeBookingId,
    this.activeBookingStatus,
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    UserRole? role,
    bool? isProfessional,
    ProfessionalStatus? professionalStatus,
    bool? emailVerified,
    String? barbershopId,
    String? activeBookingId,
    String? activeBookingStatus,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isProfessional: isProfessional ?? this.isProfessional,
      professionalStatus: professionalStatus ?? this.professionalStatus,
      emailVerified: emailVerified ?? this.emailVerified,
      barbershopId: barbershopId ?? this.barbershopId,
      activeBookingId: activeBookingId ?? this.activeBookingId,
      activeBookingStatus: activeBookingStatus ?? this.activeBookingStatus,
    );
  }
}
