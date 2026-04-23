import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoadCurrentUserRequested extends AuthEvent {
  const AuthLoadCurrentUserRequested();
}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthSignUpRequested extends AuthEvent {
  final String fullName;
  final String phone;
  final String email;
  final String password;
  final bool isProfessional;

  const AuthSignUpRequested({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.password,
    required this.isProfessional,
  });

  @override
  List<Object?> get props => [
        fullName,
        phone,
        email,
        password,
        isProfessional,
      ];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthResendVerificationEmailRequested extends AuthEvent {
  const AuthResendVerificationEmailRequested();
}