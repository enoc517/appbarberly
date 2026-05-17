import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../domain/entities/barbershop.dart';
import '../../domain/repositories/barbershop_management_repository.dart';
import '../datasources/barbershop_management_remote_datasource.dart';

class BarbershopManagementRepositoryImpl
    implements BarbershopManagementRepository {
  final BarbershopManagementRemoteDatasource _ds;
  const BarbershopManagementRepositoryImpl(this._ds);

  @override
  Future<Result<Barbershop>> create(CreateBarbershopParams params) async {
    try {
      return Ok(await _ds.create(
        ownerId: params.ownerId,
        ownerName: params.ownerName,
        params: params,
      ));
    } catch (_) {
      return const Fail(UnknownFailure('No se pudo crear la barbería'));
    }
  }

  @override
  Future<Result<Barbershop>> update(UpdateBarbershopParams params) async {
    try {
      return Ok(await _ds.update(params));
    } catch (_) {
      return const Fail(UnknownFailure('No se pudo actualizar la barbería'));
    }
  }

  @override
  Future<Result<Barbershop?>> getByOwner(String ownerId) async {
    try {
      return Ok(await _ds.getByOwner(ownerId));
    } catch (_) {
      return const Fail(UnknownFailure('No se pudo obtener la barbería'));
    }
  }
}
