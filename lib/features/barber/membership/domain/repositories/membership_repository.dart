import '../../../../../core/usecases/usecase.dart';
import '../../../barbershop_management/domain/entities/barbershop.dart';
import '../entities/barber_member.dart';
import '../entities/membership_request.dart';

abstract class MembershipRepository {
  Future<Result<List<Barbershop>>> searchBarbershops({
    required String query,
    required double radiusKm,
  });
  Future<Result<MembershipRequest>> sendRequest({
    required String barberId,
    required String barberName,
    required String barberEmail,
    required String barberAvatarUrl,
    required String barbershopId,
    required String barbershopName,
  });
  Future<Result<List<MembershipRequest>>> getPendingRequests(
    String barbershopId,
  );
  Future<Result<MembershipRequest>> reviewRequest({
    required String requestId,
    required String barbershopId,
    required bool approve,
    required String reviewedBy,
  });
  Future<Result<List<BarberMember>>> getMembers(String barbershopId);
  Future<Result<void>> leaveBarbershop(String barberId, String barbershopId);
}
