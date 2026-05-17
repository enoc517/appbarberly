import '../../../../../core/usecases/usecase.dart';
import '../entities/barber_member.dart';
import '../repositories/membership_repository.dart';

class GetBarbershopMembers
    implements UseCase<List<BarberMember>, String> {
  final MembershipRepository _repository;
  const GetBarbershopMembers(this._repository);

  @override
  Future<Result<List<BarberMember>>> call(String barbershopId) =>
      _repository.getMembers(barbershopId);
}
