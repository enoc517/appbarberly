import 'package:flutter_bloc/flutter_bloc.dart';

import 'welcome_event.dart';
import 'welcome_state.dart';

/// BLoC for the Welcome screen.
///
/// Currently handles navigation intents. Ready to be extended
/// with async checks (e.g. existing session, first-launch flags).
class WelcomeBloc extends Bloc<WelcomeEvent, WelcomeState> {
  WelcomeBloc() : super(const WelcomeState()) {
    on<WelcomeStartPressed>(_onStartPressed);
    on<WelcomeLoginPressed>(_onLoginPressed);
  }

  void _onStartPressed(
    WelcomeStartPressed event,
    Emitter<WelcomeState> emit,
  ) {
    emit(state.copyWith(navigation: WelcomeNavigation.onboarding));
    // Reset so listener fires once per tap.
    emit(state.copyWith(navigation: WelcomeNavigation.none));
  }

  void _onLoginPressed(
    WelcomeLoginPressed event,
    Emitter<WelcomeState> emit,
  ) {
    emit(state.copyWith(navigation: WelcomeNavigation.login));
    emit(state.copyWith(navigation: WelcomeNavigation.none));
  }
}
