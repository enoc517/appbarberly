import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/send_email_verification.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required SignOutUseCase signOutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required SendEmailVerificationUseCase sendEmailVerificationUseCase,
  })  : _signInUseCase = signInUseCase,
        _signUpUseCase = signUpUseCase,
        _signOutUseCase = signOutUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        _sendEmailVerificationUseCase = sendEmailVerificationUseCase,
        super(const AuthState()) {
    on<AuthLoadCurrentUserRequested>(_onLoadCurrentUserRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthResendVerificationEmailRequested>(_onResendVerificationEmailRequested);
  }

  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final SendEmailVerificationUseCase _sendEmailVerificationUseCase;

  AuthStatus _statusForUser(bool emailVerified) {
    return emailVerified
        ? AuthStatus.authenticated
        : AuthStatus.emailVerificationPending;
  }

  Future<void> _onLoadCurrentUserRequested(
    AuthLoadCurrentUserRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      final user = await _getCurrentUserUseCase();

      if (user == null) {
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          clearError: true,
        ));
        return;
      }

      emit(state.copyWith(
        status: _statusForUser(user.emailVerified),
        user: user,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      final user = await _signInUseCase(
        email: event.email,
        password: event.password,
      );

      emit(state.copyWith(
        status: _statusForUser(user.emailVerified),
        user: user,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      final user = await _signUpUseCase(
        fullName: event.fullName,
        phone: event.phone,
        email: event.email,
        password: event.password,
        isProfessional: event.isProfessional,
      );

      emit(state.copyWith(
        status: _statusForUser(user.emailVerified),
        user: user,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onResendVerificationEmailRequested(
    AuthResendVerificationEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      await _sendEmailVerificationUseCase();

      if (state.user != null) {
        emit(state.copyWith(
          status: AuthStatus.emailVerificationPending,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          clearError: true,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      await _signOutUseCase();
      emit(const AuthState(status: AuthStatus.unauthenticated));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}