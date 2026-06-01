import 'package:cloud_firestore/cloud_firestore.dart';

abstract class UserValidationSource {
  Future<bool> isPhoneRegistered(String phone, {String? excludeUserId});
}

class UserValidationDatasource implements UserValidationSource {
  final FirebaseFirestore firestore;

  UserValidationDatasource({required this.firestore});

  @override
  Future<bool> isPhoneRegistered(String phone, {String? excludeUserId}) async {
    final query = await firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .get();

    if (excludeUserId != null) {
      return query.docs.any((doc) => doc.id != excludeUserId);
    }

    return query.docs.isNotEmpty;
  }
}
