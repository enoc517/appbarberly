import '../../../../../core/usecases/usecase.dart';
import '../entities/barber_service.dart';
import '../repositories/barber_services_repository.dart';

class UpdateServiceParams {
  final String barbershopId;
  final String barberId;
  final String serviceId;
  final String? name;
  final String? description;
  final double? price;
  final int? durationMinutes;
  final String? category;
  final bool? isActive;

  const UpdateServiceParams({
    required this.barbershopId,
    required this.barberId,
    required this.serviceId,
    this.name,
    this.description,
    this.price,
    this.durationMinutes,
    this.category,
    this.isActive,
  });
}

class UpdateService implements UseCase<BarberService, UpdateServiceParams> {
  final BarberServicesRepository _repository;
  const UpdateService(this._repository);

  @override
  Future<Result<BarberService>> call(UpdateServiceParams params) =>
      _repository.updateService(
        barbershopId: params.barbershopId,
        barberId: params.barberId,
        serviceId: params.serviceId,
        name: params.name,
        description: params.description,
        price: params.price,
        durationMinutes: params.durationMinutes,
        category: params.category,
        isActive: params.isActive,
      );
}
