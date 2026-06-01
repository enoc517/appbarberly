import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this.remoteDatasource);

  final AuthRemoteDatasource remoteDatasource;

  @override
  Future<AppUser?> getCurrentUser() {
    return remoteDatasource.getCurrentUser();
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) {
    return remoteDatasource.signIn(email: email, password: password);
  }

  @override
  Future<AppUser?> signInWithGoogle() {
    return remoteDatasource.signInWithGoogle();
  }

  @override
  Future<AppUser> finalizeGoogleSignUp({required bool isProfessional}) {
    return remoteDatasource.finalizeGoogleSignUp(
      isProfessional: isProfessional,
    );
  }

  @override
  Future<AppUser> signUp({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required bool isProfessional,
  }) {
    return remoteDatasource.signUp(
      fullName: fullName,
      phone: phone,
      email: email,
      password: password,
      isProfessional: isProfessional,
    );
  }

  @override
  Future<void> signOut() {
    return remoteDatasource.signOut();
  }

  @override
  Future<void> sendEmailVerification() {
    return remoteDatasource.sendEmailVerification();
  }

  @override
  Future<void> updateUserProfile({
    required String uid,
    String? fullName,
    String? phone,
    String? profileImageUrl,
  }) {
    return remoteDatasource.updateUserProfile(
      uid: uid,
      fullName: fullName,
      phone: phone,
      profileImageUrl: profileImageUrl,
    );
  }
}
