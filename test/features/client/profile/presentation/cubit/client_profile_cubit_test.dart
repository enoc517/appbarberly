import 'dart:io';

import 'package:barberly/core/datasources/cloudinary_datasource.dart';
import 'package:barberly/core/datasources/user_validation_datasource.dart';
import 'package:barberly/features/auth/domain/entities/app_user.dart';
import 'package:barberly/features/auth/domain/repositories/auth_repository.dart';
import 'package:barberly/features/auth/domain/usecases/get_current_user.dart';
import 'package:barberly/features/auth/domain/usecases/sign_out.dart';
import 'package:barberly/features/auth/domain/usecases/update_user_profile.dart';
import 'package:barberly/features/client/profile/presentation/cubit/client_profile_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  group('ClientProfileCubit.saveProfile', () {
    late _FakeAuthRepository authRepository;
    late _FakeImageUploader imageUploader;
    late _FakeUserValidationDatasource validationDatasource;
    late ClientProfileCubit cubit;

    setUp(() {
      authRepository = _FakeAuthRepository();
      imageUploader = _FakeImageUploader();
      validationDatasource = _FakeUserValidationDatasource();
      cubit = ClientProfileCubit(
        getCurrentUser: GetCurrentUserUseCase(authRepository),
        signOut: SignOutUseCase(authRepository),
        updateUserProfile: UpdateUserProfileUseCase(authRepository),
        imageUploader: imageUploader,
        userValidationDatasource: validationDatasource,
      );
    });

    tearDown(() => cubit.close());

    test('uploads the image before saving the uploaded URL', () async {
      imageUploader.nextUrl = 'https://cdn.test/client-new.jpg';

      await cubit.saveProfile(
        fullName: 'Client Updated',
        phone: '111',
        imageFile: XFile('client.jpg'),
      );

      expect(imageUploader.calls, ['upload:users:u-client/avatar']);
      expect(authRepository.calls, ['currentUser', 'update:u-client']);
      expect(authRepository.lastUpdate?.profileImageUrl, imageUploader.nextUrl);
      expect(cubit.state.profileImageUrl, imageUploader.nextUrl);
      expect(cubit.state.userName, 'Client Updated');
    });

    test('does not persist profile changes when upload fails', () async {
      imageUploader.error = Exception('network down');

      await cubit.saveProfile(
        fullName: 'Should Not Persist',
        phone: '222',
        imageFile: XFile('client.jpg'),
      );

      expect(authRepository.updateCount, 0);
      expect(cubit.state.profileImageUrl, isNull);
      expect(cubit.state.updateError, contains('Error al subir imagen'));
      expect(cubit.state.isUpdating, isFalse);
    });

    test('keeps the previous avatar when save fails after upload', () async {
      authRepository.currentUser = authRepository.currentUser.copyWith(
        profileImageUrl: 'https://cdn.test/old.jpg',
      );
      imageUploader.nextUrl = 'https://cdn.test/new.jpg';
      authRepository.updateError = Exception('firestore unavailable');
      await cubit.loadData();

      await cubit.saveProfile(
        fullName: 'Client Updated',
        phone: '111',
        imageFile: XFile('client.jpg'),
      );

      expect(authRepository.updateCount, 1);
      expect(cubit.state.profileImageUrl, 'https://cdn.test/old.jpg');
      expect(cubit.state.updateError, contains('Error al actualizar perfil'));
      expect(cubit.state.isUpdating, isFalse);
    });

    test('clears failure state and saves retried uploaded URL', () async {
      imageUploader.error = Exception('first upload failed');
      await cubit.saveProfile(
        fullName: 'Client Updated',
        phone: '111',
        imageFile: XFile('client.jpg'),
      );

      imageUploader.error = null;
      imageUploader.nextUrl = 'https://cdn.test/retry.jpg';
      await cubit.saveProfile(
        fullName: 'Client Updated',
        phone: '111',
        imageFile: XFile('client.jpg'),
      );

      expect(authRepository.updateCount, 1);
      expect(cubit.state.profileImageUrl, 'https://cdn.test/retry.jpg');
      expect(cubit.state.updateError, isNull);
      expect(cubit.state.isUpdating, isFalse);
    });
  });
}

class _FakeImageUploader implements ImageUploadDatasource {
  String nextUrl = 'https://cdn.test/avatar.jpg';
  Object? error;
  final calls = <String>[];

  @override
  Future<String> uploadImage({
    required File file,
    required String folder,
    required String publicId,
  }) async {
    calls.add('upload:$folder:$publicId');
    final error = this.error;
    if (error != null) throw error;
    return nextUrl;
  }
}

class _FakeUserValidationDatasource implements UserValidationSource {
  @override
  Future<bool> isPhoneRegistered(String phone, {String? excludeUserId}) async {
    return false;
  }
}

class _FakeAuthRepository implements AuthRepository {
  AppUser currentUser = const AppUser(
    id: 'u-client',
    email: 'client@test.com',
    fullName: 'Client',
    phone: '111',
    role: UserRole.client,
    isProfessional: false,
    professionalStatus: ProfessionalStatus.none,
    emailVerified: true,
  );
  Object? updateError;
  _ProfileUpdate? lastUpdate;
  final calls = <String>[];
  int updateCount = 0;

  @override
  Future<AppUser?> getCurrentUser() async {
    calls.add('currentUser');
    return currentUser;
  }

  @override
  Future<void> updateUserProfile({
    required String uid,
    String? fullName,
    String? phone,
    String? profileImageUrl,
  }) async {
    calls.add('update:$uid');
    updateCount++;
    final error = updateError;
    if (error != null) throw error;
    lastUpdate = _ProfileUpdate(
      fullName: fullName,
      phone: phone,
      profileImageUrl: profileImageUrl,
    );
  }

  @override
  Future<AppUser> finalizeGoogleSignUp({required bool isProfessional}) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<AppUser> signIn({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<AppUser> signUp({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required bool isProfessional,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppUser?> signInWithGoogle() {
    throw UnimplementedError();
  }
}

class _ProfileUpdate {
  const _ProfileUpdate({this.fullName, this.phone, this.profileImageUrl});

  final String? fullName;
  final String? phone;
  final String? profileImageUrl;
}
