import '../../../../../core/usecases/usecase.dart';
import '../repositories/barber_services_repository.dart';

class DeleteServiceParams {
  final String barbershopId;
  final String barberId;
  final String serviceId;

  const DeleteServiceParams({
    required this.barbershopId,
    required this.barberId,
    required this.serviceId,
  });
}

class DeleteService implements UseCase<void, DeleteServiceParams> {
  final BarberServicesRepository _repository;
  const DeleteService(this._repository);

  @override
  Future<Result<void>> call(DeleteServiceParams params) =>
      _repository.deleteService(
        barbershopId: params.barbershopId,
        barberId: params.barberId,
        serviceId: params.serviceId,
      );
}
