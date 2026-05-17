import '../../../../../core/usecases/usecase.dart';
import '../entities/barber_service.dart';
import '../entities/barber_schedule.dart';

abstract class BarberServicesRepository {
  Future<Result<List<BarberService>>> getServices(
    String barbershopId,
    String barberId,
  );
  Future<Result<BarberService>> addService({
    required String barbershopId,
    required String barberId,
    required String name,
    required String description,
    required double price,
    required int durationMinutes,
    required String category,
  });
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
  });
  Future<Result<void>> deleteService({
    required String barbershopId,
    required String barberId,
    required String serviceId,
  });
  Future<Result<List<BarberSchedule>>> getSchedule(
    String barbershopId,
    String barberId,
  );
  Future<Result<void>> setSchedule({
    required String barbershopId,
    required String barberId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required bool isActive,
  });
}
