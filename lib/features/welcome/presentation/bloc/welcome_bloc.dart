import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/usecases/get_current_user.dart';
import 'welcome_event.dart';
import 'welcome_state.dart';

class WelcomeBloc extends Bloc<WelcomeEvent, WelcomeState> {
  WelcomeBloc({
    required GetCurrentUserUseCase getCurrentUserUseCase,
  })  : _getCurrentUserUseCase = getCurrentUserUseCase,
        super(const WelcomeState()) {
    on<WelcomeStarted>(_onStarted);
  }

  final GetCurrentUserUseCase _getCurrentUserUseCase;

  Future<void> _onStarted(
    WelcomeStarted event,
    Emitter<WelcomeState> emit,
  ) async {
    debugPrint('WELCOME START: ${DateTime.now()}');

    emit(state.copyWith(status: WelcomeStatus.loading));

    await Future.delayed(const Duration(seconds: 4));

    try {
      final user = await _getCurrentUserUseCase();

      debugPrint('WELCOME END: ${DateTime.now()}');

      if (user != null) {
        emit(state.copyWith(status: WelcomeStatus.goToHome));
      } else {
        emit(state.copyWith(status: WelcomeStatus.goToLogin));
      }
    } catch (e) {
      debugPrint('WELCOME ERROR: $e');
      emit(state.copyWith(status: WelcomeStatus.goToLogin));
    }
  }
}