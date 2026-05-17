import '../../../../../core/usecases/usecase.dart';
import '../entities/membership_request.dart';
import '../repositories/membership_repository.dart';

class SendMembershipRequestParams {
  final String barberId;
  final String barberName;
  final String barberEmail;
  final String barberAvatarUrl;
  final String barbershopId;
  final String barbershopName;

  const SendMembershipRequestParams({
    required this.barberId,
    required this.barberName,
    required this.barberEmail,
    required this.barberAvatarUrl,
    required this.barbershopId,
    required this.barbershopName,
  });
}

class SendMembershipRequest
    implements UseCase<MembershipRequest, SendMembershipRequestParams> {
  final MembershipRepository _repository;
  const SendMembershipRequest(this._repository);

  @override
  Future<Result<MembershipRequest>> call(SendMembershipRequestParams params) =>
      _repository.sendRequest(
        barberId: params.barberId,
        barberName: params.barberName,
        barberEmail: params.barberEmail,
        barberAvatarUrl: params.barberAvatarUrl,
        barbershopId: params.barbershopId,
        barbershopName: params.barbershopName,
      );
}
