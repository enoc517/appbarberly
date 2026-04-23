enum UserRole { client, barber }

class AppUser {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final UserRole role;
  final bool isProfessional;
  final bool emailVerified;

  const AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    required this.role,
    required this.isProfessional,
    required this.emailVerified,
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    UserRole? role,
    bool? isProfessional,
    bool? emailVerified,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isProfessional: isProfessional ?? this.isProfessional,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }
}