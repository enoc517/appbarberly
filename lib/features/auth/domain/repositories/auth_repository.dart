import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> getCurrentUser();

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser?> signInWithGoogle();

  Future<AppUser> finalizeGoogleSignUp({required bool isProfessional});

  Future<AppUser> signUp({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required bool isProfessional,
  });

  Future<void> signOut();

  Future<void> sendEmailVerification();
}
