import '/../../../core/error/failures.dart';
import '/../../../core/usecases/usecase.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_mock_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardMockDataSource _ds;
  const DashboardRepositoryImpl(this._ds);

  @override
  Future<Result<DashboardData>> getDashboardData(String barberId) async {
    try {
      return Ok(await _ds.fetch(barberId));
    } catch (_) {
      return const Fail(UnknownFailure('No se pudo cargar el panel'));
    }
  }
}