import '../../../../../core/usecases/usecase.dart';
import '../repositories/membership_repository.dart';

class LeaveBarbershopParams {
  final String barberId;
  final String barbershopId;

  const LeaveBarbershopParams({
    required this.barberId,
    required this.barbershopId,
  });
}

class LeaveBarbershop implements UseCase<void, LeaveBarbershopParams> {
  final MembershipRepository _repository;
  const LeaveBarbershop(this._repository);

  @override
  Future<Result<void>> call(LeaveBarbershopParams params) =>
      _repository.leaveBarbershop(params.barberId, params.barbershopId);
}
