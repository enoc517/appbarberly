import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/app_user.dart';

enum WelcomeStatus { initial, loading, goToLogin, goToHome, goToVerifyEmail }

class WelcomeState extends Equatable {
  final WelcomeStatus status;
  final AppUser? user;

  const WelcomeState({this.status = WelcomeStatus.initial, this.user});

  WelcomeState copyWith({WelcomeStatus? status, AppUser? user}) {
    return WelcomeState(status: status ?? this.status, user: user ?? this.user);
  }

  @override
  List<Object?> get props => [status, user];
}
