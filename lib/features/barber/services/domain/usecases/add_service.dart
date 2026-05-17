import '../../../../../core/usecases/usecase.dart';
import '../entities/barber_service.dart';
import '../repositories/barber_services_repository.dart';

class AddServiceParams {
  final String barbershopId;
  final String barberId;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;
  final String category;

  const AddServiceParams({
    required this.barbershopId,
    required this.barberId,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.category,
  });
}

class AddService implements UseCase<BarberService, AddServiceParams> {
  final BarberServicesRepository _repository;
  const AddService(this._repository);

  @override
  Future<Result<BarberService>> call(AddServiceParams params) =>
      _repository.addService(
        barbershopId: params.barbershopId,
        barberId: params.barberId,
        name: params.name,
        description: params.description,
        price: params.price,
        durationMinutes: params.durationMinutes,
        category: params.category,
      );
}
