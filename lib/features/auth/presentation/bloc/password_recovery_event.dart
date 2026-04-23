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

/// Paso 2: Verificación del token recibido
final class RecoveryTokenSubmitted extends PasswordRecoveryEvent {
  final String token;
  const RecoveryTokenSubmitted(this.token);

  @override
  List<Object?> get props => [token];
}

/// Paso 3: Envío de la nueva contraseña (Adaptado de Claude)
final class NewPasswordSubmitted extends PasswordRecoveryEvent {
  final String newPassword;
  final String confirmPassword;
  
  const NewPasswordSubmitted({
    required this.newPassword, 
    required this.confirmPassword
  });

  @override
  List<Object?> get props => [newPassword, confirmPassword];
}

/// Eventos de UI para la visibilidad (Adaptados de Claude)
final class PasswordVisibilityToggled extends PasswordRecoveryEvent {}
final class ConfirmPasswordVisibilityToggled extends PasswordRecoveryEvent {}