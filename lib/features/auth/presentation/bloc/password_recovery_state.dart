part of 'password_recovery_bloc.dart';

/// Define las etapas del flujo completo
enum RecoveryStatus { 
  initial, 
  loading, 
  emailSent,      // Ir a pantalla de Token
  tokenVerified,  // Ir a pantalla de Nueva Contraseña
  success,        // Éxito final
  error 
}

final class PasswordRecoveryState extends Equatable {
  const PasswordRecoveryState({
    this.status = RecoveryStatus.initial,
    this.email = '',
    this.token = '',
    this.isPasswordObscured = true,
    this.isConfirmPasswordObscured = true,
    this.errorMessage,
  });

  final RecoveryStatus status;
  final String email;
  final String token;
  final bool isPasswordObscured;
  final bool isConfirmPasswordObscured;
  final String? errorMessage;

  // Helpers para la UI
  bool get isLoading => status == RecoveryStatus.loading;
  bool get isError => status == RecoveryStatus.error;

  PasswordRecoveryState copyWith({
    RecoveryStatus? status,
    String? email,
    String? token,
    bool? isPasswordObscured,
    bool? isConfirmPasswordObscured,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PasswordRecoveryState(
      status: status ?? this.status,
      email: email ?? this.email,
      token: token ?? this.token,
      isPasswordObscured: isPasswordObscured ?? this.isPasswordObscured,
      isConfirmPasswordObscured: isConfirmPasswordObscured ?? this.isConfirmPasswordObscured,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status, email, token, isPasswordObscured, isConfirmPasswordObscured, errorMessage
  ];
}