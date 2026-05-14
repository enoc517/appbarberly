part of 'password_recovery_bloc.dart';

/// Define las etapas del flujo completo
enum RecoveryStatus { initial, loading, emailSent, error }

final class PasswordRecoveryState extends Equatable {
  const PasswordRecoveryState({
    this.status = RecoveryStatus.initial,
    this.email = '',
    this.errorMessage,
  });

  final RecoveryStatus status;
  final String email;
  final String? errorMessage;

  // Helpers para la UI
  bool get isLoading => status == RecoveryStatus.loading;
  bool get isError => status == RecoveryStatus.error;

  PasswordRecoveryState copyWith({
    RecoveryStatus? status,
    String? email,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PasswordRecoveryState(
      status: status ?? this.status,
      email: email ?? this.email,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, email, errorMessage];
}
