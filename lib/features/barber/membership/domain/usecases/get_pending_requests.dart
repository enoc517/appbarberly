import '../../../../../core/usecases/usecase.dart';
import '../entities/membership_request.dart';
import '../repositories/membership_repository.dart';

class GetPendingRequests
    implements UseCase<List<MembershipRequest>, String> {
  final MembershipRepository _repository;
  const GetPendingRequests(this._repository);

  @override
  Future<Result<List<MembershipRequest>>> call(String barbershopId) =>
      _repository.getPendingRequests(barbershopId);
}
