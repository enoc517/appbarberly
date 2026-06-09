import 'dart:io';

import 'package:barberly/core/datasources/cloudinary_datasource.dart';
import 'package:barberly/core/datasources/user_validation_datasource.dart';
import 'package:barberly/features/auth/domain/entities/app_user.dart';
import 'package:barberly/features/auth/domain/repositories/auth_repository.dart';
import 'package:barberly/features/auth/domain/usecases/get_current_user.dart';
import 'package:barberly/features/auth/domain/usecases/sign_out.dart';
import 'package:barberly/features/auth/domain/usecases/update_user_profile.dart';
import 'package:barberly/features/barber/account/presentation/cubit/barber_profile_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  group('BarberProfileCubit.saveProfile', () {
    late _FakeAuthRepository authRepository;
    late _FakeImageUploader imageUploader;
    late _FakeUserValidationDatasource validationDatasource;
    late BarberProfileCubit cubit;

    setUp(() {
      authRepository = _FakeAuthRepository();
      imageUploader = _FakeImageUploader();
      validationDatasource = _FakeUserValidationDatasource();
      cubit = BarberProfileCubit(
        getCurrentUser: GetCurrentUserUseCase(authRepository),
        signOut: SignOutUseCase(authRepository),
        updateUserProfile: UpdateUserProfileUseCase(authRepository),
        imageUploader: imageUploader,
        userValidationDatasource: validationDatasource,
      );
    });

    tearDown(() => cubit.close());

    test('uploads the image before saving the uploaded URL', () async {
      imageUploader.nextUrl = 'https://cdn.test/barber-new.jpg';

      await cubit.saveProfile(
        fullName: 'Barber Updated',
        phone: '333',
        imageFile: XFile('barber.jpg'),
      );

      expect(imageUploader.calls, ['upload:users:u-barber/avatar']);
      expect(authRepository.calls, ['currentUser', 'update:u-barber']);
      expect(authRepository.lastUpdate?.profileImageUrl, imageUploader.nextUrl);
      expect(cubit.state.profileImageUrl, imageUploader.nextUrl);
      expect(cubit.state.userName, 'Barber Updated');
    });

    test('does not persist profile changes when upload fails', () async {
      imageUploader.error = Exception('network down');

      await cubit.saveProfile(
        fullName: 'Should Not Persist',
        phone: '444',
        imageFile: XFile('barber.jpg'),
      );

      expect(authRepository.updateCount, 0);
      expect(cubit.state.profileImageUrl, isNull);
      expect(cubit.state.updateError, contains('Error al subir imagen'));
    });

    test('keeps the previous avatar when save fails after upload', () async {
      authRepository.currentUser = authRepository.currentUser.copyWith(
        profileImageUrl: 'https://cdn.test/old-barber.jpg',
      );
      imageUploader.nextUrl = 'https://cdn.test/new-barber.jpg';
      authRepository.updateError = Exception('firestore unavailable');
      await cubit.loadData();

      await cubit.saveProfile(
        fullName: 'Barber Updated',
        phone: '333',
        imageFile: XFile('barber.jpg'),
      );

      expect(authRepository.updateCount, 1);
      expect(cubit.state.profileImageUrl, 'https://cdn.test/old-barber.jpg');
      expect(cubit.state.updateError, contains('Error al actualizar perfil'));
    });

    test('clears failure state and saves retried uploaded URL', () async {
      imageUploader.error = Exception('first upload failed');
      await cubit.saveProfile(
        fullName: 'Barber Updated',
        phone: '333',
        imageFile: XFile('barber.jpg'),
      );

      imageUploader.error = null;
      imageUploader.nextUrl = 'https://cdn.test/barber-retry.jpg';
      await cubit.saveProfile(
        fullName: 'Barber Updated',
        phone: '333',
        imageFile: XFile('barber.jpg'),
      );

      expect(authRepository.updateCount, 1);
      expect(cubit.state.profileImageUrl, 'https://cdn.test/barber-retry.jpg');
      expect(cubit.state.updateError, isNull);
    });

    test(
      'shows a friendly error when the new phone is already in use',
      () async {
        validationDatasource.phoneIsTaken = true;

        await cubit.saveProfile(fullName: 'Barber Updated', phone: '999-0000');

        expect(authRepository.updateCount, 0);
        expect(
          cubit.state.phoneError,
          contains('Este teléfono ya está registrado'),
        );
        expect(cubit.state.isUpdating, isFalse);
      },
    );
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
  bool phoneIsTaken = false;

  @override
  Future<bool> isPhoneRegistered(String phone, {String? excludeUserId}) async {
    return phoneIsTaken;
  }
}

class _FakeAuthRepository implements AuthRepository {
  AppUser currentUser = const AppUser(
    id: 'u-barber',
    email: 'barber@test.com',
    fullName: 'Barber',
    phone: '333',
    role: UserRole.barber,
    isProfessional: true,
    professionalStatus: ProfessionalStatus.approved,
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
    lastUpdate = _ProfileUpdate(profileImageUrl: profileImageUrl);
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
  const _ProfileUpdate({this.profileImageUrl});

  final String? profileImageUrl;
}
