import '../../../../../core/usecases/usecase.dart';
import '../entities/membership_request.dart';
import '../repositories/membership_repository.dart';

class ReviewMembershipRequestParams {
  final String requestId;
  final String barbershopId;
  final bool approve;
  final String reviewedBy;

  const ReviewMembershipRequestParams({
    required this.requestId,
    required this.barbershopId,
    required this.approve,
    required this.reviewedBy,
  });
}

class ReviewMembershipRequest
    implements UseCase<MembershipRequest, ReviewMembershipRequestParams> {
  final MembershipRepository _repository;
  const ReviewMembershipRequest(this._repository);

  @override
  Future<Result<MembershipRequest>> call(
    ReviewMembershipRequestParams params,
  ) => _repository.reviewRequest(
    requestId: params.requestId,
    barbershopId: params.barbershopId,
    approve: params.approve,
    reviewedBy: params.reviewedBy,
  );
}
