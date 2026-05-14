import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/send_password_reset_email.dart';

part 'password_recovery_event.dart';
part 'password_recovery_state.dart';

class PasswordRecoveryBloc
    extends Bloc<PasswordRecoveryEvent, PasswordRecoveryState> {
  PasswordRecoveryBloc({
    required SendPasswordResetEmailUseCase sendPasswordResetEmailUseCase,
  }) : _sendPasswordResetEmailUseCase = sendPasswordResetEmailUseCase,
       super(const PasswordRecoveryState()) {
    on<RecoveryEmailSubmitted>(_onEmailSubmitted);
  }

  final SendPasswordResetEmailUseCase _sendPasswordResetEmailUseCase;

  Future<void> _onEmailSubmitted(
    RecoveryEmailSubmitted event,
    Emitter<PasswordRecoveryState> emit,
  ) async {
    emit(state.copyWith(status: RecoveryStatus.loading, clearError: true));
    try {
      await _sendPasswordResetEmailUseCase(email: event.email);
      emit(
        state.copyWith(status: RecoveryStatus.emailSent, email: event.email),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: RecoveryStatus.error,
          errorMessage: _readableMessage(e),
        ),
      );
    }
  }

  String _readableMessage(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ')
        ? message.replaceFirst('Exception: ', '')
        : message;
  }
}
