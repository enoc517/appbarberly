import '../../../domain/entities/barbershop.dart';

sealed class BarbershopProfileState {
  const BarbershopProfileState();
}

class BarbershopProfileLoading extends BarbershopProfileState {
  const BarbershopProfileLoading();
}

class BarbershopProfileLoaded extends BarbershopProfileState {
  final Barbershop barbershop;
  const BarbershopProfileLoaded(this.barbershop);
}

class BarbershopProfileError extends BarbershopProfileState {
  final String message;
  const BarbershopProfileError(this.message);
}