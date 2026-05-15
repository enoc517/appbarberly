import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/finalize_google_sign_up.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required SignInWithGoogleUseCase signInWithGoogleUseCase,
    required FinalizeGoogleSignUpUseCase finalizeGoogleSignUpUseCase,
    required SignOutUseCase signOutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
  }) : _signInUseCase = signInUseCase,
       _signUpUseCase = signUpUseCase,
       _signInWithGoogleUseCase = signInWithGoogleUseCase,
       _finalizeGoogleSignUpUseCase = finalizeGoogleSignUpUseCase,
       _signOutUseCase = signOutUseCase,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       super(const AuthState()) {
    on<AuthLoadCurrentUserRequested>(_onLoadCurrentUserRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<AuthFinalizeGoogleSignUpRequested>(_onFinalizeGoogleSignUpRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
  }

  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final FinalizeGoogleSignUpUseCase _finalizeGoogleSignUpUseCase;
  final SignOutUseCase _signOutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

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
        emit(
          state.copyWith(status: AuthStatus.unauthenticated, clearError: true),
        );
        return;
      }

      emit(
        state.copyWith(
          status: _statusForUser(user.emailVerified),
          user: user,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()),
      );
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

      emit(
        state.copyWith(
          status: _statusForUser(user.emailVerified),
          user: user,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onSignInWithGoogleRequested(
    AuthSignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      final user = await _signInWithGoogleUseCase();
      if (user == null) {
        emit(
          state.copyWith(
            status: AuthStatus.googleRoleSelection,
            clearError: true,
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearError: true,
        ),
      );
    } catch (e) {
      final message = e.toString();
      if (message.contains('google-sign-in-cancelled')) {
        emit(
          state.copyWith(status: AuthStatus.unauthenticated, clearError: true),
        );
        return;
      }

      emit(state.copyWith(status: AuthStatus.failure, errorMessage: message));
    }
  }

  Future<void> _onFinalizeGoogleSignUpRequested(
    AuthFinalizeGoogleSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      final user = await _finalizeGoogleSignUpUseCase(
        isProfessional: event.isProfessional,
      );

      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()),
      );
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

      emit(
        state.copyWith(
          status: _statusForUser(user.emailVerified),
          user: user,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()),
      );
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
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()),
      );
    }
  }
}
