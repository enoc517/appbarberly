import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../domain/entities/barber.dart';
import '../../domain/entities/barbershop.dart';
import '../../domain/entities/service.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/repositories/barbershop_repository.dart';
import '../datasources/barbershop_firestore_datasource.dart';

class BarbershopRepositoryImpl implements BarbershopRepository {
  BarbershopRepositoryImpl({required BarbershopFirestoreDataSource dataSource})
      : _dataSource = dataSource;

  final BarbershopFirestoreDataSource _dataSource;

  @override
  Future<Result<Barbershop>> getBarbershop(String id) async {
    try {
      final dto = await _dataSource.getBarbershop(id);
      final entity = dto.shop.toEntity(
        services: dto.services,
        barbers: dto.barbers,
        slotsByDay: dto.slotsByDay,
      );
      return Ok(entity);
    } on StateError catch (e) {
      return Fail(NotFoundFailure(e.message));
    } catch (e) {
      return Fail(UnknownFailure(e.toString()));
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
      await _dataSource.confirmBooking(
        barbershopId: barbershopId,
        serviceId: service.id,
        barberId: barber.id,
        slotStartTime: slot.startTime,
        durationMinutes: service.duration.inMinutes,
        price: service.price,
      );
      return const Ok(null);
    } on StateError catch (e) {
      return Fail(NotFoundFailure(e.message));
    } catch (e) {
      return Fail(UnknownFailure(e.toString()));
    }
  }
}