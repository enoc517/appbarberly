import '../../../../../core/usecases/usecase.dart';
import '../entities/barbershop.dart';
import '../repositories/barbershop_management_repository.dart';

class GetBarbershopByOwner implements UseCase<Barbershop?, String> {
  final BarbershopManagementRepository _repository;
  const GetBarbershopByOwner(this._repository);

  @override
  Future<Result<Barbershop?>> call(String ownerId) =>
      _repository.getByOwner(ownerId);
}
