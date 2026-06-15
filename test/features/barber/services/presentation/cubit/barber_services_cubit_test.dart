import 'package:flutter_test/flutter_test.dart';

import 'package:barberly/core/usecases/usecase.dart';
import 'package:barberly/features/barber/services/domain/entities/barber_schedule.dart';
import 'package:barberly/features/barber/services/domain/entities/barber_service.dart';
import 'package:barberly/features/barber/services/domain/repositories/barber_services_repository.dart';
import 'package:barberly/features/barber/services/domain/usecases/add_service.dart';
import 'package:barberly/features/barber/services/domain/usecases/delete_service.dart';
import 'package:barberly/features/barber/services/domain/usecases/get_barber_services.dart';
import 'package:barberly/features/barber/services/domain/usecases/update_service.dart';
import 'package:barberly/features/barber/services/presentation/cubit/barber_services_cubit.dart';
import 'package:barberly/features/barber/services/presentation/cubit/barber_services_state.dart';

void main() {
  group('BarberServicesCubit', () {
    late _FakeBarberServicesRepository repository;
    late BarberServicesCubit cubit;

    setUp(() {
      repository = _FakeBarberServicesRepository();
      cubit = BarberServicesCubit(
        getBarberServices: GetBarberServices(repository),
        addService: AddService(repository),
        updateService: UpdateService(repository),
        deleteService: DeleteService(repository),
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('addService rejects durations above the allowed maximum', () async {
      await cubit.load('shop-1', 'barber-1');

      await cubit.addService(
        name: 'Corte premium',
        description: 'Servicio largo',
        price: 12000,
        durationMinutes: kMaxServiceDurationMinutes + 1,
        category: 'corte',
      );

      expect(cubit.state, isA<BarberServicesError>());
      expect(repository.addCalls, isEmpty);
    });

    test('updateService rejects durations below the allowed minimum', () async {
      await cubit.load('shop-1', 'barber-1');

      await cubit.updateService(
        serviceId: 'service-1',
        durationMinutes: kMinServiceDurationMinutes - 1,
      );

      expect(cubit.state, isA<BarberServicesError>());
      expect(repository.updateCalls, isEmpty);
    });
  });
}

class _FakeBarberServicesRepository implements BarberServicesRepository {
  final addCalls = <int>[];
  final updateCalls = <int?>[];

  @override
  Future<Result<List<BarberService>>> getServices(
    String barbershopId,
    String barberId,
  ) async {
    return const Ok(<BarberService>[]);
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
    addCalls.add(durationMinutes);
    return Ok(
      BarberService(
        id: 'service-1',
        name: name,
        description: description,
        price: price,
        durationMinutes: durationMinutes,
        category: category,
        isActive: true,
      ),
    );
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
    updateCalls.add(durationMinutes);
    return Ok(
      BarberService(
        id: serviceId,
        name: name ?? 'Servicio',
        description: description ?? '',
        price: price ?? 0,
        durationMinutes: durationMinutes ?? 60,
        category: category ?? 'corte',
        isActive: isActive ?? true,
      ),
    );
  }

  @override
  Future<Result<void>> deleteService({
    required String barbershopId,
    required String barberId,
    required String serviceId,
  }) async {
    return const Ok(null);
  }

  @override
  Future<Result<List<BarberSchedule>>> getSchedule(
    String barbershopId,
    String barberId,
  ) async {
    return const Ok(<BarberSchedule>[]);
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
    return const Ok(null);
  }
}
