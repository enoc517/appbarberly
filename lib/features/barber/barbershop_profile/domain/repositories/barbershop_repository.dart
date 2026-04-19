import '../../../../../core/usecases/usecase.dart';
import '../entities/barbershop.dart';
import '../entities/barber.dart';
import '../entities/service.dart';
import '../entities/time_slot.dart';

abstract class BarbershopRepository {
  Future<Result<Barbershop>> getBarbershop(String id);

  Future<Result<void>> confirmBooking({
    required String barbershopId,
    required Service service,
    required Barber barber,
    required TimeSlot slot,
  });
}