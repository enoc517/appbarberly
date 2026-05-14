import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/repositories/password_recovery_repository.dart';
import '../datasources/password_recovery_remote_datasource.dart';

class PasswordRecoveryRepositoryImpl implements PasswordRecoveryRepository {
  PasswordRecoveryRepositoryImpl(this.remoteDatasource);

  final PasswordRecoveryRemoteDatasource remoteDatasource;

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await remoteDatasource.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_messageForCode(e.code));
    }
  }

  String _messageForCode(String code) {
    return switch (code) {
      'invalid-email' => 'Ingresa un correo electrónico válido.',
      'user-not-found' => 'No existe una cuenta asociada a este correo.',
      'too-many-requests' =>
        'Demasiados intentos. Intenta nuevamente más tarde.',
      'network-request-failed' =>
        'Revisa tu conexión a internet e intenta de nuevo.',
      _ => 'No se pudo enviar el correo de recuperación.',
    };
  }
}
