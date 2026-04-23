import '../../../../../core/usecases/usecase.dart';
import '../entities/barber.dart';
import '../entities/service.dart';
import '../entities/time_slot.dart';
import '../repositories/barbershop_repository.dart';

class ConfirmBookingParams {
  final String barbershopId;
  final Service service;
  final Barber barber;
  final TimeSlot slot;

  const ConfirmBookingParams({
    required this.barbershopId,
    required this.service,
    required this.barber,
    required this.slot,
  });
}

class ConfirmBooking implements UseCase<void, ConfirmBookingParams> {
  final BarbershopRepository _repository;
  const ConfirmBooking(this._repository);

  @override
  Future<Result<void>> call(ConfirmBookingParams p) => _repository.confirmBooking(
        barbershopId: p.barbershopId,
        service: p.service,
        barber: p.barber,
        slot: p.slot,
      );
}