import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../domain/entities/barber.dart';
import '../../domain/entities/barbershop.dart';
import '../../domain/entities/service.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/repositories/barbershop_repository.dart';
import '../datasources/barbershop_mock_datasource.dart';

class BarbershopRepositoryImpl implements BarbershopRepository {
  final BarbershopMockDataSource _dataSource;
  const BarbershopRepositoryImpl(this._dataSource);

  @override
  Future<Result<Barbershop>> getBarbershop(String id) async {
    try {
      final data = await _dataSource.fetchBarbershop(id);
      return Ok(data);
    } catch (e) {
      return const Fail(UnknownFailure('No se pudo cargar la barbería'));
    }
  }

  @override
  Future<Result<void>> confirmBooking({
    required String barbershopId,
    required Service service,
    required Barber barber,
    required TimeSlot slot,
  }) async {
    try {
      await _dataSource.confirmBooking();
      return const Ok(null);
    } catch (e) {
      return const Fail(ServerFailure('No se pudo confirmar la reserva'));
    }
  }
}