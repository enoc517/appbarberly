import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../barbershop_management/domain/entities/barbershop.dart';
import '../../domain/entities/barber_member.dart';
import '../../domain/entities/membership_request.dart';
import '../../domain/repositories/membership_repository.dart';
import '../datasources/membership_remote_datasource.dart';

class MembershipRepositoryImpl implements MembershipRepository {
  final MembershipRemoteDatasource _ds;
  const MembershipRepositoryImpl(this._ds);

  @override
  Future<Result<List<Barbershop>>> searchBarbershops({
    required String query,
    required double radiusKm,
  }) async {
    try {
      return Ok(await _ds.searchBarbershops(query: query, radiusKm: radiusKm));
    } catch (_) {
      return const Fail(UnknownFailure('No se pudieron buscar barberías'));
    }
  }

  @override
  Future<Result<MembershipRequest>> sendRequest({
    required String barberId,
    required String barberName,
    required String barberEmail,
    required String barberAvatarUrl,
    required String barbershopId,
    required String barbershopName,
  }) async {
    try {
      return Ok(
        await _ds.sendRequest(
          barberId: barberId,
          barberName: barberName,
          barberEmail: barberEmail,
          barberAvatarUrl: barberAvatarUrl,
          barbershopId: barbershopId,
          barbershopName: barbershopName,
        ),
      );
    } catch (_) {
      return const Fail(UnknownFailure('No se pudo enviar la solicitud'));
    }
  }

  @override
  Future<Result<List<MembershipRequest>>> getPendingRequests(
    String barbershopId,
  ) async {
    try {
      return Ok(await _ds.getPendingRequests(barbershopId));
    } catch (_) {
      return const Fail(
        UnknownFailure('No se pudieron obtener las solicitudes'),
      );
    }
  }

  @override
  Future<Result<MembershipRequest>> reviewRequest({
    required String requestId,
    required String barbershopId,
    required bool approve,
    required String reviewedBy,
  }) async {
    try {
      return Ok(
        await _ds.reviewRequest(
          requestId: requestId,
          barbershopId: barbershopId,
          approve: approve,
          reviewedBy: reviewedBy,
        ),
      );
    } catch (_) {
      return const Fail(UnknownFailure('No se pudo revisar la solicitud'));
    }
  }

  @override
  Future<Result<List<BarberMember>>> getMembers(String barbershopId) async {
    try {
      return Ok(await _ds.getMembers(barbershopId));
    } catch (_) {
      return const Fail(UnknownFailure('No se pudieron obtener los miembros'));
    }
  }

  @override
  Future<Result<void>> leaveBarbershop(
    String barberId,
    String barbershopId,
  ) async {
    try {
      await _ds.leaveBarbershop(barberId, barbershopId);
      return const Ok(null);
    } catch (_) {
      return const Fail(UnknownFailure('No se pudo salir de la barbería'));
    }
  }
}
