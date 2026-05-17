import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../domain/entities/barber_service.dart';
import '../../domain/entities/barber_schedule.dart';
import '../../domain/repositories/barber_services_repository.dart';
import '../datasources/barber_services_remote_datasource.dart';

class BarberServicesRepositoryImpl implements BarberServicesRepository {
  final BarberServicesRemoteDatasource _ds;
  const BarberServicesRepositoryImpl(this._ds);

  @override
  Future<Result<List<BarberService>>> getServices(
    String barbershopId,
    String barberId,
  ) async {
    try {
      return Ok(await _ds.getServices(barbershopId, barberId));
    } catch (_) {
      return const Fail(UnknownFailure('No se pudieron obtener los servicios'));
    }
  }

  @override
  Future<Result<BarberService>> addService({
    required String barbershopId,
    required String barberId,
    required String name,
    required String description,
    required double price,
    required int durationMinutes,
    required String category,
  }) async {
    try {
      return Ok(await _ds.addService(
        barbershopId: barbershopId,
        barberId: barberId,
        name: name,
        description: description,
        price: price,
        durationMinutes: durationMinutes,
        category: category,
      ));
    } catch (_) {
      return const Fail(UnknownFailure('No se pudo agregar el servicio'));
    }
  }

  @override
  Future<Result<BarberService>> updateService({
    required String barbershopId,
    required String barberId,
    required String serviceId,
    String? name,
    String? description,
    double? price,
    int? durationMinutes,
    String? category,
    bool? isActive,
  }) async {
    try {
      return Ok(await _ds.updateService(
        barbershopId: barbershopId,
        barberId: barberId,
        serviceId: serviceId,
        name: name,
        description: description,
        price: price,
        durationMinutes: durationMinutes,
        category: category,
        isActive: isActive,
      ));
    } catch (_) {
      return const Fail(
        UnknownFailure('No se pudo actualizar el servicio'),
      );
    }
  }

  @override
  Future<Result<void>> deleteService({
    required String barbershopId,
    required String barberId,
    required String serviceId,
  }) async {
    try {
      await _ds.deleteService(
        barbershopId: barbershopId,
        barberId: barberId,
        serviceId: serviceId,
      );
      return const Ok(null);
    } catch (_) {
      return const Fail(UnknownFailure('No se pudo eliminar el servicio'));
    }
  }

  @override
  Future<Result<List<BarberSchedule>>> getSchedule(
    String barbershopId,
    String barberId,
  ) async {
    try {
      return Ok(await _ds.getSchedule(barbershopId, barberId));
    } catch (_) {
      return const Fail(UnknownFailure('No se pudo obtener el horario'));
    }
  }

  @override
  Future<Result<void>> setSchedule({
    required String barbershopId,
    required String barberId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required bool isActive,
  }) async {
    try {
      await _ds.setSchedule(
        barbershopId: barbershopId,
        barberId: barberId,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        isActive: isActive,
      );
      return const Ok(null);
    } catch (_) {
      return const Fail(UnknownFailure('No se pudo guardar el horario'));
    }
  }
}
