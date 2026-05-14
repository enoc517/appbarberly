abstract class PasswordRecoveryRepository {
  Future<void> sendPasswordResetEmail({required String email});
}
