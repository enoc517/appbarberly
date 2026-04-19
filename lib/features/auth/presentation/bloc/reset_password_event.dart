part of 'reset_password_bloc.dart';

/// Eventos del flujo de Restablecer Contraseña.
///
/// Siguiendo el principio de inmutabilidad, todos los eventos extienden
/// [Equatable] para garantizar comparaciones por valor y evitar rebuilds
/// innecesarios en el BlocBuilder.
sealed class ResetPasswordEvent extends Equatable {
  const ResetPasswordEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Alterna la visibilidad del campo "Nueva Contraseña".
final class NewPasswordVisibilityToggled extends ResetPasswordEvent {
  const NewPasswordVisibilityToggled();
}

/// Alterna la visibilidad del campo "Confirmar Contraseña".
final class ConfirmPasswordVisibilityToggled extends ResetPasswordEvent {
  const ConfirmPasswordVisibilityToggled();
}

/// Notifica cambios en el campo de nueva contraseña.
///
/// Útil para validaciones reactivas (por ejemplo, deshabilitar el CTA
/// hasta que se cumplan las reglas mínimas).
final class NewPasswordChanged extends ResetPasswordEvent {
  const NewPasswordChanged(this.password);

  final String password;

  @override
  List<Object?> get props => <Object?>[password];
}

/// Notifica cambios en el campo de confirmación de contraseña.
final class ConfirmPasswordChanged extends ResetPasswordEvent {
  const ConfirmPasswordChanged(this.password);

  final String password;

  @override
  List<Object?> get props => <Object?>[password];
}

/// Dispara el envío del formulario para actualizar la contraseña.
///
/// El BLoC debe validar internamente antes de invocar el caso de uso
/// asociado en la capa de dominio.
final class ResetPasswordSubmitted extends ResetPasswordEvent {
  const ResetPasswordSubmitted({
    required this.newPassword,
    required this.confirmPassword,
  });

  final String newPassword;
  final String confirmPassword;

  @override
  List<Object?> get props => <Object?>[newPassword, confirmPassword];
}