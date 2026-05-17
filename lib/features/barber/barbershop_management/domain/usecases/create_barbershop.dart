import '../../../../../core/usecases/usecase.dart';
import '../entities/barbershop.dart';
import '../repositories/barbershop_management_repository.dart';

class CreateBarbershop implements UseCase<Barbershop, CreateBarbershopParams> {
  final BarbershopManagementRepository _repository;
  const CreateBarbershop(this._repository);

  @override
  Future<Result<Barbershop>> call(CreateBarbershopParams params) =>
      _repository.create(params);
}
