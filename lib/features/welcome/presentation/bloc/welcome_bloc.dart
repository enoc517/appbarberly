import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/usecases/get_current_user.dart';
import 'welcome_event.dart';
import 'welcome_state.dart';

class WelcomeBloc extends Bloc<WelcomeEvent, WelcomeState> {
  WelcomeBloc({required GetCurrentUserUseCase getCurrentUserUseCase})
    : _getCurrentUserUseCase = getCurrentUserUseCase,
      super(const WelcomeState()) {
    on<WelcomeStarted>(_onStarted);
  }

  final GetCurrentUserUseCase _getCurrentUserUseCase;

  Future<void> _onStarted(
    WelcomeStarted event,
    Emitter<WelcomeState> emit,
  ) async {
    emit(state.copyWith(status: WelcomeStatus.loading));

    try {
      final user = await _getCurrentUserUseCase();

      if (user == null) {
        emit(state.copyWith(status: WelcomeStatus.goToLogin));
        return;
      }

      if (!user.emailVerified) {
        emit(state.copyWith(status: WelcomeStatus.goToVerifyEmail, user: user));
        return;
      }

      emit(state.copyWith(status: WelcomeStatus.goToHome, user: user));
    } catch (e) {
      emit(state.copyWith(status: WelcomeStatus.goToLogin));
    }
  }
}
