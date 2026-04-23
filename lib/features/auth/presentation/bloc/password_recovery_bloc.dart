import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'password_recovery_event.dart';
part 'password_recovery_state.dart';

class PasswordRecoveryBloc extends Bloc<PasswordRecoveryEvent, PasswordRecoveryState> {
  PasswordRecoveryBloc() : super(const PasswordRecoveryState()) {
    on<RecoveryEmailSubmitted>(_onEmailSubmitted);
    on<RecoveryTokenSubmitted>(_onTokenSubmitted);
    on<NewPasswordSubmitted>(_onNewPasswordSubmitted);
    on<PasswordVisibilityToggled>(_onPasswordToggled);
    on<ConfirmPasswordVisibilityToggled>(_onConfirmPasswordToggled);
  }

  /// PROCESO 1: Enviar correo de recuperación
  Future<void> _onEmailSubmitted(
    RecoveryEmailSubmitted event, Emitter<PasswordRecoveryState> emit
  ) async {
    emit(state.copyWith(status: RecoveryStatus.loading, clearError: true));
    try {
      // Simulación de envío de correo (Repository call)
      await Future.delayed(const Duration(milliseconds: 800));
      emit(state.copyWith(status: RecoveryStatus.emailSent, email: event.email));
    } catch (e) {
      emit(state.copyWith(status: RecoveryStatus.error, errorMessage: 'Correo no registrado'));
    }
  }

  /// PROCESO 2: Validar el Token
  Future<void> _onTokenSubmitted(
    RecoveryTokenSubmitted event, Emitter<PasswordRecoveryState> emit
  ) async {
    emit(state.copyWith(status: RecoveryStatus.loading, clearError: true));
    try {
      // Simulación de validación (Repository call usando state.email y event.token)
      await Future.delayed(const Duration(milliseconds: 800));
      emit(state.copyWith(status: RecoveryStatus.tokenVerified, token: event.token));
    } catch (e) {
      emit(state.copyWith(status: RecoveryStatus.error, errorMessage: 'Código incorrecto'));
    }
  }

  /// PROCESO 3: Cambio final de contraseña (Adaptado de Claude)
  Future<void> _onNewPasswordSubmitted(
    NewPasswordSubmitted event, Emitter<PasswordRecoveryState> emit
  ) async {
    emit(state.copyWith(status: RecoveryStatus.loading, clearError: true));
    try {
      // Aquí enviarías state.email, state.token y event.newPassword al servidor
      await Future.delayed(const Duration(milliseconds: 1200));
      emit(state.copyWith(status: RecoveryStatus.success));
    } catch (e) {
      emit(state.copyWith(status: RecoveryStatus.error, errorMessage: 'No se pudo actualizar'));
    }
  }

  void _onPasswordToggled(PasswordVisibilityToggled event, Emitter<PasswordRecoveryState> emit) {
    emit(state.copyWith(isPasswordObscured: !state.isPasswordObscured));
  }

  void _onConfirmPasswordToggled(ConfirmPasswordVisibilityToggled event, Emitter<PasswordRecoveryState> emit) {
    emit(state.copyWith(isConfirmPasswordObscured: !state.isConfirmPasswordObscured));
  }
}