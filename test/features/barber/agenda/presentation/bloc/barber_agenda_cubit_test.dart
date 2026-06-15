import 'dart:async';

import 'package:barberly/features/barber/agenda/presentation/bloc/barber_agenda_cubit.dart';
import 'package:barberly/features/barber/services/domain/entities/barber_service.dart';
import 'package:barberly/features/barber/services/domain/entities/barber_schedule.dart';
import 'package:barberly/features/barber/services/domain/usecases/get_barber_schedule.dart';
import 'package:barberly/features/barber/services/domain/repositories/barber_services_repository.dart';
import 'package:barberly/core/events/barbershop_event_bus.dart';
import 'package:barberly/features/bookings/domain/entities/booking.dart';
import 'package:barberly/features/bookings/domain/repositories/bookings_repository.dart';
import 'package:barberly/core/usecases/usecase.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BarberAgendaCubit', () {
    late _FakeBookingsRepository bookingsRepository;
    late FakeFirebaseFirestore firestore;
    late BarberAgendaCubit cubit;

    setUp(() {
      bookingsRepository = _FakeBookingsRepository();
      firestore = FakeFirebaseFirestore();
      cubit = BarberAgendaCubit(
        bookingsRepository: bookingsRepository,
        firestore: firestore,
        getBarberSchedule: GetBarberSchedule(_FakeBarberServicesRepository()),
        userId: 'barber-1',
        eventBus: BarbershopEventBus.instance,
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test(
      'completeBooking delegates to the repository and returns true',
      () async {
        final booking = _activeBooking();

        expectLater(
          BarbershopEventBus.instance.stream,
          emits(BarbershopEvent.bookingUpdated),
        );

        final success = await cubit.completeBooking(booking);

        expect(success, isTrue);
        expect(bookingsRepository.calls, ['complete:booking-1:client-1']);
      },
    );

    test(
      'completeBooking returns false without entering an error state when the repository fails',
      () async {
        final failingRepository = _FakeBookingsRepository()
          ..throwOnComplete = true;
        final localCubit = BarberAgendaCubit(
          bookingsRepository: failingRepository,
          firestore: FakeFirebaseFirestore(),
          getBarberSchedule: GetBarberSchedule(_FakeBarberServicesRepository()),
          userId: 'barber-1',
          eventBus: BarbershopEventBus.instance,
        );

        addTearDown(localCubit.close);

        final success = await localCubit.completeBooking(_activeBooking());

        expect(success, isFalse);
        expect(localCubit.state, isNot(isA<BarberAgendaError>()));
      },
    );

    test('completeBooking is blocked before slotEnd', () async {
      final now = DateTime.now();
      final booking = _activeBookingWithTimes(
        slotStart: now.subtract(const Duration(minutes: 30)),
        slotEnd: now.add(const Duration(minutes: 30)),
      );

      final success = await cubit.completeBooking(booking);

      expect(success, isFalse);
      expect(bookingsRepository.calls, isEmpty);
    });

    test('canCompleteBooking allows completion after slotEnd', () {
      final now = DateTime.now();
      final booking = _activeBookingWithTimes(
        slotStart: now.subtract(const Duration(hours: 1)),
        slotEnd: now.subtract(const Duration(minutes: 1)),
      );

      expect(cubit.canCompleteBooking(booking, now: now), isTrue);
    });

    test('completeBooking returns false for inactive bookings', () async {
      final booking = _inactiveBooking();

      final success = await cubit.completeBooking(booking);

      expect(success, isFalse);
      expect(bookingsRepository.calls, isEmpty);
    });

    test(
      'cancelBooking delegates barber cancellation to the repository',
      () async {
        final booking = _activeBooking();

        final success = await cubit.cancelBooking(
          booking,
          cancellationReason: 'Emergencia personal',
        );

        expect(success, isTrue);
        expect(bookingsRepository.calls, [
          'cancel:booking-1:client-1:barber:Emergencia personal',
        ]);
      },
    );

    test('cancelBooking returns false for inactive bookings', () async {
      final booking = _inactiveBooking();

      final success = await cubit.cancelBooking(booking);

      expect(success, isFalse);
      expect(bookingsRepository.calls, isEmpty);
    });

    test('load watches only the current barber agenda', () async {
      await firestore.collection('users').doc('barber-1').set({
        'barbershopId': 'shop-1',
      });

      await cubit.load(day: DateTime(2026, 6, 3));

      expect(bookingsRepository.watchArgs, isNotNull);
      expect(bookingsRepository.watchArgs!.$1, 'shop-1');
      expect(bookingsRepository.watchArgs!.$2, 'barber-1');
      expect(bookingsRepository.watchArgs!.$3, '2026-06-03');
    });

    test('scheduleUpdated refreshes the current agenda', () async {
      await firestore.collection('users').doc('barber-1').set({
        'barbershopId': 'shop-1',
      });

      await cubit.load(day: DateTime(2026, 6, 3));
      expect(bookingsRepository.watchCount, 1);

      BarbershopEventBus.instance.emit(BarbershopEvent.scheduleUpdated);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bookingsRepository.watchCount, 2);
      expect(bookingsRepository.watchArgs!.$1, 'shop-1');
      expect(bookingsRepository.watchArgs!.$2, 'barber-1');
      expect(bookingsRepository.watchArgs!.$3, '2026-06-03');
    });
  });
}

class _FakeBarberServicesRepository implements BarberServicesRepository {
  @override
  Future<Result<List<BarberSchedule>>> getSchedule(
    String barbershopId,
    String barberId,
  ) async {
    const today = 3;
    return Ok(<BarberSchedule>[
      BarberSchedule(
        id: 'day-$today',
        dayOfWeek: today,
        startTime: '09:00',
        endTime: '17:00',
        isActive: true,
      ),
    ]);
  }

  @override
  Future<Result<List<BarberService>>> getServices(
    String barbershopId,
    String barberId,
  ) {
    throw UnimplementedError();
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
  }) {
    throw UnimplementedError();
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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> deleteService({
    required String barbershopId,
    required String barberId,
    required String serviceId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<void>> setSchedule({
    required String barbershopId,
    required String barberId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required bool isActive,
  }) {
    throw UnimplementedError();
  }
}

class _FakeBookingsRepository implements BookingsRepository {
  final calls = <String>[];
  (String, String, String)? watchArgs;
  var watchCount = 0;
  final _agendaController = StreamController<List<Booking>>.broadcast();
  bool throwOnComplete = false;

  @override
  Future<String> createBooking(BookingDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<void> rescheduleBooking({
    required String bookingId,
    required BookingDraft draft,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> cancelBooking({
    required String bookingId,
    required String clientId,
    required BookingCancellationActor cancelledBy,
    String? cancellationReason,
  }) async {
    final reason = cancellationReason == null || cancellationReason.isEmpty
        ? ''
        : ':$cancellationReason';
    calls.add('cancel:$bookingId:$clientId:${cancelledBy.name}$reason');
  }

  @override
  Future<void> completeBooking({
    required String bookingId,
    required String clientId,
  }) async {
    if (throwOnComplete) {
      throw StateError('boom');
    }
    calls.add('complete:$bookingId:$clientId');
  }

  @override
  Stream<List<Booking>> watchBarberAgenda({
    required String barbershopId,
    required String barberId,
    required String dateKey,
  }) {
    watchCount++;
    watchArgs = (barbershopId, barberId, dateKey);
    return _agendaController.stream;
  }

  @override
  Stream<List<Booking>> watchBarbershopBookings({
    required String barbershopId,
    required DateTime start,
    required DateTime end,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Booking>> watchClientBookings(String clientId) {
    throw UnimplementedError();
  }
}

Booking _activeBooking() {
  return _activeBookingWithTimes(
    slotStart: DateTime(2026, 6, 3, 10),
    slotEnd: DateTime(2026, 6, 3, 10, 30),
  );
}

Booking _activeBookingWithTimes({
  required DateTime slotStart,
  required DateTime slotEnd,
}) {
  return Booking(
    id: 'booking-1',
    clientId: 'client-1',
    barberId: 'barber-1',
    barbershopId: 'shop-1',
    serviceId: 'service-1',
    dateKey: '2026-06-03',
    slotStart: slotStart,
    slotEnd: slotEnd,
    status: AppointmentBookingStatus.confirmed,
    price: 5000,
    durationMinutes: 30,
    clientSnapshot: const BookingSnapshot(name: 'Cliente Uno'),
    barberSnapshot: const BookingSnapshot(name: 'Barbero Uno'),
    shopSnapshot: const BookingSnapshot(name: 'Shop Uno'),
    serviceSnapshot: const BookingSnapshot(name: 'Corte'),
  );
}

Booking _inactiveBooking() {
  return Booking(
    id: 'booking-2',
    clientId: 'client-1',
    barberId: 'barber-1',
    barbershopId: 'shop-1',
    serviceId: 'service-1',
    dateKey: '2026-06-03',
    slotStart: DateTime(2026, 6, 3, 11),
    slotEnd: DateTime(2026, 6, 3, 11, 30),
    status: AppointmentBookingStatus.completed,
    price: 5000,
    durationMinutes: 30,
    clientSnapshot: const BookingSnapshot(name: 'Cliente Uno'),
    barberSnapshot: const BookingSnapshot(name: 'Barbero Uno'),
    shopSnapshot: const BookingSnapshot(name: 'Shop Uno'),
    serviceSnapshot: const BookingSnapshot(name: 'Corte'),
  );
}
