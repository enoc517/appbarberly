import 'package:equatable/equatable.dart';

/// Events for the Welcome feature.
abstract class WelcomeEvent extends Equatable {
  const WelcomeEvent();

  @override
  List<Object?> get props => [];
}

/// User tapped "Comenzar" — navigate to registration / onboarding.
class WelcomeStartPressed extends WelcomeEvent {
  const WelcomeStartPressed();
}

/// User tapped "Ya tengo una cuenta" — navigate to login.
class WelcomeLoginPressed extends WelcomeEvent {
  const WelcomeLoginPressed();
}
