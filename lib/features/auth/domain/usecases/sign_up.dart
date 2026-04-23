import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<AppUser> call({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required bool isProfessional,
  }) {
    return repository.signUp(
      fullName: fullName,
      phone: phone,
      email: email,
      password: password,
      isProfessional: isProfessional,
    );
  }
}