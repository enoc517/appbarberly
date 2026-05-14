part of 'password_recovery_bloc.dart';

sealed class PasswordRecoveryEvent extends Equatable {
  const PasswordRecoveryEvent();

  @override
  List<Object?> get props => [];
}

/// Paso 1: Envío de correo para recuperación
final class RecoveryEmailSubmitted extends PasswordRecoveryEvent {
  final String email;
  const RecoveryEmailSubmitted(this.email);

  @override
  List<Object?> get props => [email];
}
