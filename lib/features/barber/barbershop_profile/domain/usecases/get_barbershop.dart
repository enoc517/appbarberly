import '../../../../../core/usecases/usecase.dart';
import '../entities/barbershop.dart';
import '../repositories/barbershop_repository.dart';

class GetBarbershop implements UseCase<Barbershop, String> {
  final BarbershopRepository _repository;
  const GetBarbershop(this._repository);

  @override
  Future<Result<Barbershop>> call(String id) =>
      _repository.getBarbershop(id);
}