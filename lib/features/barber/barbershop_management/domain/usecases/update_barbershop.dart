import '../../../../../core/usecases/usecase.dart';
import '../entities/barbershop.dart';
import '../repositories/barbershop_management_repository.dart';

class UpdateBarbershop implements UseCase<Barbershop, UpdateBarbershopParams> {
  final BarbershopManagementRepository _repository;
  const UpdateBarbershop(this._repository);

  @override
  Future<Result<Barbershop>> call(UpdateBarbershopParams params) =>
      _repository.update(params);
}
