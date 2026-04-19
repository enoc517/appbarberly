import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'reset_password_event.dart';
part 'reset_password_state.dart';

/// BLoC que orquesta el flujo de Restablecer Contraseña.
///
/// Esta capa de presentación es agnóstica de la fuente de datos: el envío
/// del formulario se delega mediante un callback inyectable ([onSubmit])
/// que, a futuro, debe apuntar al caso de uso correspondiente en la capa
/// de dominio (p. ej. `ResetPasswordUseCase`).
///
/// De esta manera, mantenemos limpia la frontera Presentación ↔ Dominio
/// sin acoplar el BLoC a `FirebaseAuth` directamente.
class ResetPasswordBloc extends Bloc<ResetPasswordEvent, ResetPasswordState> {
  ResetPasswordBloc({
    Future<void> Function(String newPassword)? onSubmit,
  })  : _onSubmit = onSubmit,
        super(const ResetPasswordState.initial()) {
    on<NewPasswordVisibilityToggled>(_onNewPasswordVisibilityToggled);
    on<ConfirmPasswordVisibilityToggled>(_onConfirmPasswordVisibilityToggled);
    on<NewPasswordChanged>(_onNewPasswordChanged);
    on<ConfirmPasswordChanged>(_onConfirmPasswordChanged);
    on<ResetPasswordSubmitted>(_onResetPasswordSubmitted);
  }

  /// Callback inyectable que comunica con la capa de dominio.
  /// Si es `null`, se simula un éxito tras un pequeño delay (útil en dev).
  final Future<void> Function(String newPassword)? _onSubmit;

  void _onNewPasswordVisibilityToggled(
    NewPasswordVisibilityToggled event,
    Emitter<ResetPasswordState> emit,
  ) {
    emit(state.copyWith(
      isNewPasswordObscured: !state.isNewPasswordObscured,
    ));
  }

  void _onConfirmPasswordVisibilityToggled(
    ConfirmPasswordVisibilityToggled event,
    Emitter<ResetPasswordState> emit,
  ) {
    emit(state.copyWith(
      isConfirmPasswordObscured: !state.isConfirmPasswordObscured,
    ));
  }

  void _onNewPasswordChanged(
    NewPasswordChanged event,
    Emitter<ResetPasswordState> emit,
  ) {
    // Limpia cualquier error previo al escribir para no confundir al usuario.
    if (state.isError) {
      emit(state.copyWith(status: AuthStatus.initial, clearError: true));
    }
  }

  void _onConfirmPasswordChanged(
    ConfirmPasswordChanged event,
    Emitter<ResetPasswordState> emit,
  ) {
    if (state.isError) {
      emit(state.copyWith(status: AuthStatus.initial, clearError: true));
    }
  }

  Future<void> _onResetPasswordSubmitted(
    ResetPasswordSubmitted event,
    Emitter<ResetPasswordState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      if (_onSubmit != null) {
        await _onSubmit!(event.newPassword);
      } else {
        // Simulación para entornos donde aún no está cableado el UseCase.
        await Future<void>.delayed(const Duration(milliseconds: 800));
      }
      emit(state.copyWith(status: AuthStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'No pudimos actualizar tu contraseña. Intenta de nuevo.',
      ));
    }
  }
}