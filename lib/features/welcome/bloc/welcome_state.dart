import 'package:equatable/equatable.dart';

/// Possible navigation targets from the Welcome screen.
enum WelcomeNavigation { none, login, onboarding }

/// State for the Welcome feature.
class WelcomeState extends Equatable {
  final WelcomeNavigation navigation;

  const WelcomeState({this.navigation = WelcomeNavigation.none});

  WelcomeState copyWith({WelcomeNavigation? navigation}) {
    return WelcomeState(
      navigation: navigation ?? this.navigation,
    );
  }

  @override
  List<Object?> get props => [navigation];
}
