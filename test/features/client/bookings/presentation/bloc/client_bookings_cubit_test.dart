import 'dart:async';

import 'package:barberly/features/bookings/domain/entities/booking.dart';
import 'package:barberly/features/bookings/domain/repositories/bookings_repository.dart';
import 'package:barberly/features/client/bookings/presentation/bloc/client_bookings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClientBookingsCubit', () {
    late _FakeBookingsRepository repository;
    late ClientBookingsCubit cubit;

    setUp(() {
      repository = _FakeBookingsRepository();
      cubit = ClientBookingsCubit(repository: repository, clientId: 'client-1');
    });

    tearDown(() async {
      await cubit.close();
      await repository.controller.close();
    });

    test('cancelBooking delegates to the client cancellation flow', () async {
      final booking = _activeBooking();

      await cubit.cancelBooking(booking);

      expect(repository.calls, ['cancel:booking-1:client-1:client']);
    });

    test('cancelBooking ignores inactive bookings', () async {
      await cubit.cancelBooking(_inactiveBooking());

      expect(repository.calls, isEmpty);
    });

    test('activeBooking returns the first active booking', () {
      final loaded = ClientBookingsLoaded([
        _inactiveBooking(),
        _activeBooking(id: 'booking-2'),
        _activeBooking(id: 'booking-3'),
      ]);

      expect(loaded.activeBooking?.id, 'booking-2');
    });

    test('watch emits loaded bookings from the stream', () async {
      cubit.watch();
      final bookings = [_activeBooking()];
      repository.controller.add(bookings);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<ClientBookingsLoaded>());
      expect((cubit.state as ClientBookingsLoaded).bookings, bookings);
    });
  });
}

class _FakeBookingsRepository implements BookingsRepository {
  final calls = <String>[];
  final controller = StreamController<List<Booking>>.broadcast();

  @override
  Future<String> createBooking(BookingDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<void> cancelBooking({
    required String bookingId,
    required String clientId,
    required BookingCancellationActor cancelledBy,
  }) async {
    calls.add('cancel:$bookingId:$clientId:${cancelledBy.name}');
  }

  @override
  Future<void> completeBooking({
    required String bookingId,
    required String clientId,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<List<Booking>> watchBarberAgenda({
    required String barbershopId,
    required String barberId,
    required String dateKey,
  }) {
    throw UnimplementedError();
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
    return controller.stream;
  }
}

Booking _activeBooking({String id = 'booking-1'}) {
  return Booking(
    id: id,
    clientId: 'client-1',
    barberId: 'barber-1',
    barbershopId: 'shop-1',
    serviceId: 'service-1',
    dateKey: '2026-06-03',
    slotStart: DateTime(2026, 6, 3, 10),
    slotEnd: DateTime(2026, 6, 3, 10, 30),
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
    id: 'booking-inactive',
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
