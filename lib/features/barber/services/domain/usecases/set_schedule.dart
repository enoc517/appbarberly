import '../../../../../core/usecases/usecase.dart';
import '../repositories/barber_services_repository.dart';

class SetScheduleParams {
  final String barbershopId;
  final String barberId;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final bool isActive;

  const SetScheduleParams({
    required this.barbershopId,
    required this.barberId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });
}

class SetSchedule implements UseCase<void, SetScheduleParams> {
  final BarberServicesRepository _repository;
  const SetSchedule(this._repository);

  @override
  Future<Result<void>> call(SetScheduleParams params) =>
      _repository.setSchedule(
        barbershopId: params.barbershopId,
        barberId: params.barberId,
        dayOfWeek: params.dayOfWeek,
        startTime: params.startTime,
        endTime: params.endTime,
        isActive: params.isActive,
      );
}
