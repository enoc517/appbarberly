import '../repositories/auth_repository.dart';

class UpdateUserProfileUseCase {
  final AuthRepository repository;

  UpdateUserProfileUseCase(this.repository);

  Future<void> call({
    required String uid,
    String? fullName,
    String? phone,
    String? profileImageUrl,
  }) {
    return repository.updateUserProfile(
      uid: uid,
      fullName: fullName,
      phone: phone,
      profileImageUrl: profileImageUrl,
    );
  }
}
