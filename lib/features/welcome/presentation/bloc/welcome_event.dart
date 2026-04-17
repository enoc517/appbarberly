import 'package:equatable/equatable.dart';

abstract class WelcomeEvent extends Equatable {
  const WelcomeEvent();

  @override
  List<Object?> get props => [];
}

/// Se dispara al iniciar la pantalla
class WelcomeStarted extends WelcomeEvent {
  const WelcomeStarted();
}