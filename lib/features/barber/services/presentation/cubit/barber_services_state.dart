import '../../domain/entities/barber_service.dart';

sealed class BarberServicesState {
  const BarberServicesState();
}

class BarberServicesInitial extends BarberServicesState {
  const BarberServicesInitial();
}

class BarberServicesLoading extends BarberServicesState {
  const BarberServicesLoading();
}

class BarberServicesLoaded extends BarberServicesState {
  final List<BarberService> services;
  const BarberServicesLoaded(this.services);
}

class BarberServiceAdded extends BarberServicesState {
  final BarberService service;
  const BarberServiceAdded(this.service);
}

class BarberServiceUpdated extends BarberServicesState {
  final BarberService service;
  const BarberServiceUpdated(this.service);
}

class BarberServiceDeleted extends BarberServicesState {
  const BarberServiceDeleted();
}

class BarberServicesError extends BarberServicesState {
  final String message;
  const BarberServicesError(this.message);
}
