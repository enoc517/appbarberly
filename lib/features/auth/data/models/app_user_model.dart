import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.email,
    super.fullName,
    super.phone,
    required super.role,
    required super.isProfessional,
    required super.professionalStatus,
    required super.emailVerified,
    super.barbershopId,
    super.activeBookingId,
    super.activeBookingStatus,
  });

  factory AppUserModel.fromFirebaseUser(
    User user, {
    String? fullName,
    String? phone,
    required UserRole role,
    bool isProfessional = false,
    ProfessionalStatus professionalStatus = ProfessionalStatus.none,
    bool emailVerified = false,
    String? barbershopId,
    String? activeBookingId,
    String? activeBookingStatus,
  }) {
    return AppUserModel(
      id: user.uid,
      email: user.email ?? '',
      fullName: fullName ?? user.displayName,
      phone: phone,
      role: role,
      isProfessional: isProfessional,
      professionalStatus: professionalStatus,
      emailVerified: emailVerified,
      barbershopId: barbershopId,
      activeBookingId: activeBookingId,
      activeBookingStatus: activeBookingStatus,
    );
  }

  factory AppUserModel.fromMap(String id, Map<String, dynamic> data) {
    final roleValue = (data['role'] as String?)?.toLowerCase() ?? 'client';
    final role = roleValue == 'barber' ? UserRole.barber : UserRole.client;
    final isProfessional = data['isProfessional'] as bool? ?? false;
    final status = _professionalStatusFromMap(
      data['professionalStatus'] as String?,
      role: role,
      isProfessional: isProfessional,
    );

    return AppUserModel(
      id: id,
      email: data['email'] as String? ?? '',
      fullName: data['fullName'] as String?,
      phone: data['phone'] as String?,
      role: role,
      isProfessional: isProfessional,
      professionalStatus: status,
      emailVerified: data['emailVerified'] as bool? ?? false,
      barbershopId: data['barbershopId'] as String?,
      activeBookingId: data['activeBookingId'] as String?,
      activeBookingStatus: data['activeBookingStatus'] as String?,
    );
  }

  static ProfessionalStatus _professionalStatusFromMap(
    String? value, {
    required UserRole role,
    required bool isProfessional,
  }) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return ProfessionalStatus.pending;
      case 'approved':
        return ProfessionalStatus.approved;
      case 'rejected':
        return ProfessionalStatus.rejected;
      case 'none':
        return ProfessionalStatus.none;
    }

    if (role == UserRole.barber) return ProfessionalStatus.approved;
    if (isProfessional) return ProfessionalStatus.pending;
    return ProfessionalStatus.none;
  }

  Map<String, dynamic> toMap({bool includeCreatedAt = false}) {
    final map = <String, dynamic>{
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'role': role.name,
      'isProfessional': isProfessional,
      'professionalStatus': professionalStatus.name,
      'emailVerified': emailVerified,
      'barbershopId': barbershopId,
      'activeBookingId': activeBookingId,
      'activeBookingStatus': activeBookingStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (includeCreatedAt) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }

    return map;
  }
}
