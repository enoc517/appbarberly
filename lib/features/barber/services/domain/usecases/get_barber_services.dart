import '../../../../../core/usecases/usecase.dart';
import '../entities/barber_service.dart';
import '../repositories/barber_services_repository.dart';

class GetBarberServicesParams {
  final String barbershopId;
  final String barberId;

  const GetBarberServicesParams({
    required this.barbershopId,
    required this.barberId,
  });
}

class GetBarberServices
    implements UseCase<List<BarberService>, GetBarberServicesParams> {
  final BarberServicesRepository _repository;
  const GetBarberServices(this._repository);

  @override
  Future<Result<List<BarberService>>> call(GetBarberServicesParams params) =>
      _repository.getServices(params.barbershopId, params.barberId);
}
