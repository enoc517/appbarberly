import 'package:firebase_auth/firebase_auth.dart';

abstract class PasswordRecoveryRemoteDatasource {
  Future<void> sendPasswordResetEmail({required String email});
}

class PasswordRecoveryRemoteDatasourceImpl
    implements PasswordRecoveryRemoteDatasource {
  PasswordRecoveryRemoteDatasourceImpl({FirebaseAuth? firebaseAuth})
    : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }
}
