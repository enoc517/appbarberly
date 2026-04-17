import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'welcome_event.dart';
import 'welcome_state.dart';

class WelcomeBloc extends Bloc<WelcomeEvent, WelcomeState> {
  WelcomeBloc() : super(const WelcomeState()) {
    on<WelcomeStarted>(_onStarted);
  }

  Future<void> _onStarted(
    WelcomeStarted event,
    Emitter<WelcomeState> emit,
  ) async {
    debugPrint('WELCOME START: ${DateTime.now()}');

    emit(state.copyWith(status: WelcomeStatus.loading));

    await Future.delayed(const Duration(seconds: 4));

    debugPrint('WELCOME END: ${DateTime.now()}');

    final bool isLoggedIn = false;

    if (isLoggedIn) {
      emit(state.copyWith(status: WelcomeStatus.goToHome));
    } else {
      emit(state.copyWith(status: WelcomeStatus.goToLogin));
    }
  }
}
