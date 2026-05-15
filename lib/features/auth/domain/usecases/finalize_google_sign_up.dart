import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class FinalizeGoogleSignUpUseCase {
  final AuthRepository repository;

  FinalizeGoogleSignUpUseCase(this.repository);

  Future<AppUser> call({required bool isProfessional}) {
    return repository.finalizeGoogleSignUp(isProfessional: isProfessional);
  }
}
