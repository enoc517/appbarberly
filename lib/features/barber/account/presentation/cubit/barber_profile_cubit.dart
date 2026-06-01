import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../auth/domain/usecases/get_current_user.dart';
import '../../../../auth/domain/usecases/sign_out.dart';
import '../../../../auth/domain/usecases/update_user_profile.dart';
import '../../../../../core/datasources/cloudinary_datasource.dart';
import '../../../../../core/datasources/user_validation_datasource.dart';

class BarberProfileState extends Equatable {
  final bool isLoading;
  final String userName;
  final String userEmail;
  final String? userPhone;
  final String? profileImageUrl;
  final bool isUpdating;
  final String? updateError;
  final String? phoneError;
  final String? errorMessage;

  const BarberProfileState({
    this.isLoading = true,
    this.userName = '',
    this.userEmail = '',
    this.userPhone,
    this.profileImageUrl,
    this.isUpdating = false,
    this.updateError,
    this.phoneError,
    this.errorMessage,
  });

  BarberProfileState copyWith({
    bool? isLoading,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? profileImageUrl,
    bool? isUpdating,
    String? updateError,
    String? phoneError,
    String? errorMessage,
  }) {
    return BarberProfileState(
      isLoading: isLoading ?? this.isLoading,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isUpdating: isUpdating ?? this.isUpdating,
      updateError: updateError,
      phoneError: phoneError,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    userName,
    userEmail,
    userPhone,
    profileImageUrl,
    isUpdating,
    updateError,
    phoneError,
    errorMessage,
  ];
}

class BarberProfileCubit extends Cubit<BarberProfileState> {
  final GetCurrentUserUseCase _getCurrentUser;
  final SignOutUseCase _signOut;
  final UpdateUserProfileUseCase _updateUserProfile;
  final ImageUploadDatasource _imageUploader;
  final UserValidationSource _userValidationDatasource;

  BarberProfileCubit({
    required GetCurrentUserUseCase getCurrentUser,
    required SignOutUseCase signOut,
    required UpdateUserProfileUseCase updateUserProfile,
    required ImageUploadDatasource imageUploader,
    required UserValidationSource userValidationDatasource,
  }) : _getCurrentUser = getCurrentUser,
       _signOut = signOut,
       _updateUserProfile = updateUserProfile,
       _imageUploader = imageUploader,
       _userValidationDatasource = userValidationDatasource,
       super(const BarberProfileState());

  Future<void> loadData() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final user = await _getCurrentUser();
      if (user == null) {
        emit(
          const BarberProfileState(
            isLoading: false,
            userName: '',
            userEmail: '',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          isLoading: false,
          userName: user.fullName ?? 'Barbero',
          userEmail: user.email,
          userPhone: user.phone,
          profileImageUrl: user.profileImageUrl,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> uploadProfileImage(XFile imageFile) async {
    await saveProfile(imageFile: imageFile);
  }

  Future<void> saveProfile({
    String? fullName,
    String? phone,
    XFile? imageFile,
  }) async {
    emit(state.copyWith(isUpdating: true, updateError: null, phoneError: null));

    try {
      final user = await _getCurrentUser();
      if (user == null) {
        emit(
          state.copyWith(
            isUpdating: false,
            updateError: 'Usuario no encontrado',
          ),
        );
        return;
      }

      if (phone != null && phone != user.phone) {
        final isPhoneTaken = await _userValidationDatasource.isPhoneRegistered(
          phone,
          excludeUserId: user.id,
        );

        if (isPhoneTaken) {
          emit(
            state.copyWith(
              isUpdating: false,
              phoneError: 'Este teléfono ya está registrado por otro usuario',
            ),
          );
          return;
        }
      }

      String? uploadedImageUrl;
      if (imageFile != null) {
        try {
          uploadedImageUrl = await _imageUploader.uploadImage(
            file: File(imageFile.path),
            folder: 'users',
            publicId: '${user.id}/avatar',
          );
        } catch (e) {
          emit(
            state.copyWith(
              isUpdating: false,
              updateError: 'Error al subir imagen: ${e.toString()}',
            ),
          );
          return;
        }
      }

      try {
        await _updateUserProfile(
          uid: user.id,
          fullName: fullName,
          phone: phone,
          profileImageUrl: uploadedImageUrl,
        );
      } catch (e) {
        emit(
          state.copyWith(
            isUpdating: false,
            updateError: 'Error al actualizar perfil: ${e.toString()}',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          isUpdating: false,
          userName: fullName ?? state.userName,
          userPhone: phone ?? state.userPhone,
          profileImageUrl: uploadedImageUrl ?? state.profileImageUrl,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isUpdating: false,
          updateError: 'Error al actualizar perfil: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> updateProfile({String? fullName, String? phone}) async {
    await saveProfile(fullName: fullName, phone: phone);
  }

  Future<void> logout() async {
    await _signOut();
  }
}
