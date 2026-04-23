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
    required super.emailVerified,
  });

  factory AppUserModel.fromFirebaseUser(
    User user, {
    String? fullName,
    String? phone,
    required UserRole role,
    bool isProfessional = false,
    bool emailVerified = false,
  }) {
    return AppUserModel(
      id: user.uid,
      email: user.email ?? '',
      fullName: fullName ?? user.displayName,
      phone: phone,
      role: role,
      isProfessional: isProfessional,
      emailVerified: emailVerified,
    );
  }

  factory AppUserModel.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    final roleValue = (data['role'] as String?)?.toLowerCase() ?? 'client';

    return AppUserModel(
      id: id,
      email: data['email'] as String? ?? '',
      fullName: data['fullName'] as String?,
      phone: data['phone'] as String?,
      role: roleValue == 'barber' ? UserRole.barber : UserRole.client,
      isProfessional: data['isProfessional'] as bool? ?? false,
      emailVerified: data['emailVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap({
    bool includeCreatedAt = false,
  }) {
    final map = <String, dynamic>{
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'role': role.name,
      'isProfessional': isProfessional,
      'emailVerified': emailVerified,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (includeCreatedAt) {
      map['createdAt'] = FieldValue.serverTimestamp();
    }

    return map;
  }
}