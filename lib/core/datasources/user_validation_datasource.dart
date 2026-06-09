import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/phone_utils.dart';

class PhoneAlreadyRegisteredException implements Exception {
  const PhoneAlreadyRegisteredException([
    this.message = 'Este teléfono ya está registrado por otro usuario.',
  ]);

  final String message;

  @override
  String toString() => message;
}

abstract class UserValidationSource {
  Future<bool> isPhoneRegistered(String phone, {String? excludeUserId});
}

class UserValidationDatasource implements UserValidationSource {
  final FirebaseFirestore firestore;

  UserValidationDatasource({required this.firestore});

  @override
  Future<bool> isPhoneRegistered(String phone, {String? excludeUserId}) async {
    final normalizedPhone = normalizePhoneNumber(phone);
    if (normalizedPhone.isEmpty) return false;

    final snapshot = await firestore
        .collection('phone_numbers')
        .doc(normalizedPhone)
        .get();

    if (!snapshot.exists) return false;

    final ownerId = snapshot.data()?['userId'] as String?;
    return ownerId != null && ownerId != excludeUserId;
  }
}
