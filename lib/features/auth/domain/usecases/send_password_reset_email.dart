import '../repositories/password_recovery_repository.dart';

class SendPasswordResetEmailUseCase {
  final PasswordRecoveryRepository repository;

  SendPasswordResetEmailUseCase(this.repository);

  Future<void> call({required String email}) {
    return repository.sendPasswordResetEmail(email: email);
  }
}
