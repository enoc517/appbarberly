import '../../../../../core/usecases/usecase.dart';
import '../entities/barber_schedule.dart';
import '../repositories/barber_services_repository.dart';

class GetBarberScheduleParams {
  final String barbershopId;
  final String barberId;

  const GetBarberScheduleParams({
    required this.barbershopId,
    required this.barberId,
  });
}

class GetBarberSchedule
    implements UseCase<List<BarberSchedule>, GetBarberScheduleParams> {
  final BarberServicesRepository _repository;
  const GetBarberSchedule(this._repository);

  @override
  Future<Result<List<BarberSchedule>>> call(GetBarberScheduleParams params) =>
      _repository.getSchedule(params.barbershopId, params.barberId);
}
