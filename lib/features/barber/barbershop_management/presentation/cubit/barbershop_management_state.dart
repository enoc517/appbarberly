import '../../domain/entities/barbershop.dart';

sealed class BarbershopManagementState {
  const BarbershopManagementState();
}

class BarbershopManagementInitial extends BarbershopManagementState {
  const BarbershopManagementInitial();
}

class BarbershopManagementLoading extends BarbershopManagementState {
  const BarbershopManagementLoading();
}

class BarbershopCreated extends BarbershopManagementState {
  final Barbershop barbershop;
  const BarbershopCreated(this.barbershop);
}

class BarbershopUpdated extends BarbershopManagementState {
  final Barbershop barbershop;
  const BarbershopUpdated(this.barbershop);
}

class BarbershopLoaded extends BarbershopManagementState {
  final Barbershop? barbershop;
  const BarbershopLoaded(this.barbershop);
}

class BarbershopManagementError extends BarbershopManagementState {
  final String message;
  const BarbershopManagementError(this.message);
}
