part of 'reset_password_bloc.dart';

/// Estados de autenticación para el flujo de Restablecer Contraseña.
///
/// Se modela de forma unificada con [AuthStatus] para facilitar el
/// consumo desde la UI y seguir el patrón solicitado:
/// `AuthInitial`, `AuthLoading`, `AuthSuccess`, `AuthError`.
enum AuthStatus { initial, loading, success, error }

/// Estado del BLoC de Restablecer Contraseña.
///
/// Mantiene tanto la información de UI (visibilidad de campos)
/// como el estado del proceso asíncrono (status + mensaje de error).
final class ResetPasswordState extends Equatable {
  const ResetPasswordState({
    this.status = AuthStatus.initial,
    this.isNewPasswordObscured = true,
    this.isConfirmPasswordObscured = true,
    this.errorMessage,
  });

  /// Estado inicial: campos ocultos y sin errores.
  const ResetPasswordState.initial()
      : status = AuthStatus.initial,
        isNewPasswordObscured = true,
        isConfirmPasswordObscured = true,
        errorMessage = null;

  final AuthStatus status;
  final bool isNewPasswordObscured;
  final bool isConfirmPasswordObscured;
  final String? errorMessage;

  // Azúcar sintáctico para el consumo desde la UI.
  bool get isLoading => status == AuthStatus.loading;
  bool get isSuccess => status == AuthStatus.success;
  bool get isError => status == AuthStatus.error;

  ResetPasswordState copyWith({
    AuthStatus? status,
    bool? isNewPasswordObscured,
    bool? isConfirmPasswordObscured,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ResetPasswordState(
      status: status ?? this.status,
      isNewPasswordObscured:
          isNewPasswordObscured ?? this.isNewPasswordObscured,
      isConfirmPasswordObscured:
          isConfirmPasswordObscured ?? this.isConfirmPasswordObscured,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        isNewPasswordObscured,
        isConfirmPasswordObscured,
        errorMessage,
      ];
}