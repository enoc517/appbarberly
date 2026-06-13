import 'dart:async';

import 'package:barberly/core/events/barbershop_event_bus.dart';
import 'package:barberly/features/bookings/domain/entities/booking.dart';
import 'package:barberly/features/bookings/domain/repositories/bookings_repository.dart';
import 'package:barberly/features/reviews/domain/entities/barbershop_review.dart';
import 'package:barberly/features/reviews/domain/repositories/reviews_repository.dart';
import 'package:barberly/features/client/bookings/presentation/bloc/client_bookings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClientBookingsCubit', () {
    late _FakeBookingsRepository repository;
    late _FakeReviewsRepository reviewsRepository;
    late ClientBookingsCubit cubit;

    setUp(() {
      repository = _FakeBookingsRepository();
      reviewsRepository = _FakeReviewsRepository();
      cubit = ClientBookingsCubit(
        repository: repository,
        reviewsRepository: reviewsRepository,
        clientId: 'client-1',
        eventBus: BarbershopEventBus.instance,
      );
    });

    tearDown(() async {
      await cubit.close();
      await repository.controller.close();
    });

    test('cancelBooking delegates to the client cancellation flow', () async {
      final booking = _activeBooking();

      expectLater(
        BarbershopEventBus.instance.stream,
        emits(BarbershopEvent.bookingUpdated),
      );

      await cubit.cancelBooking(booking);

      expect(repository.calls, ['cancel:booking-1:client-1:client']);
    });

    test('cancelBooking ignores inactive bookings', () async {
      await cubit.cancelBooking(_inactiveBooking());

      expect(repository.calls, isEmpty);
    });

    test('upcomingBookings are sorted from nearest to latest', () {
      final loaded = ClientBookingsLoaded([
        _inactiveBooking(),
        _activeBooking(
          id: 'booking-2',
          slotStart: DateTime(2026, 6, 3, 11),
          slotEnd: DateTime(2026, 6, 3, 11, 30),
        ),
        _activeBooking(
          id: 'booking-3',
          slotStart: DateTime(2026, 6, 3, 9),
          slotEnd: DateTime(2026, 6, 3, 9, 30),
        ),
      ]);

      expect(loaded.upcomingBookings.map((booking) => booking.id), [
        'booking-3',
        'booking-2',
      ]);
    });

    test('activeBooking returns the nearest upcoming booking', () {
      final loaded = ClientBookingsLoaded([
        _activeBooking(
          id: 'booking-later',
          slotStart: DateTime(2026, 6, 3, 12),
          slotEnd: DateTime(2026, 6, 3, 12, 30),
        ),
        _activeBooking(
          id: 'booking-sooner',
          slotStart: DateTime(2026, 6, 3, 9),
          slotEnd: DateTime(2026, 6, 3, 9, 30),
        ),
      ]);

      expect(loaded.activeBooking?.id, 'booking-sooner');
    });

    test('penaltyBookings returns bookings with penalties', () {
      final loaded = ClientBookingsLoaded([
        _activeBooking(),
        _cancelledWithPenaltyBooking(),
        _cancelledWithoutPenaltyBooking(),
      ]);

      expect(loaded.penaltyBookings.map((booking) => booking.id), [
        'booking-penalty',
      ]);
    });

    test('watch emits loaded bookings from the stream', () async {
      cubit.watch();
      final bookings = [_activeBooking()];
      repository.controller.add(bookings);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, isA<ClientBookingsLoaded>());
      expect((cubit.state as ClientBookingsLoaded).bookings, bookings);
    });

    test('createReview delegates to the reviews repository', () async {
      final result = await cubit.createReview(
        booking: _inactiveBooking(status: AppointmentBookingStatus.completed),
        rating: 5,
        comment: 'Excelente',
      );

      expect(result, isTrue);
      expect(reviewsRepository.calls, [
        'review:booking-inactive:client-1:5:Excelente',
      ]);
    });

    test('createReview rejects already reviewed bookings', () async {
      final result = await cubit.createReview(
        booking: _inactiveBooking(
          status: AppointmentBookingStatus.completed,
          reviewed: true,
        ),
        rating: 5,
      );

      expect(result, isFalse);
      expect(reviewsRepository.calls, isEmpty);
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

class _FakeReviewsRepository implements ReviewsRepository {
  final calls = <String>[];

  @override
  Future<String> createReview({
    required String bookingId,
    required String clientId,
    required int rating,
    String? comment,
  }) async {
    calls.add('review:$bookingId:$clientId:$rating:${comment ?? ''}');
    return bookingId;
  }

  @override
  Future<List<BarbershopReview>> getLatestReviews(
    String barbershopId, {
    int limit = 6,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<BarbershopReview>> getReviewsPage(
    String barbershopId, {
    int limit = 10,
    DateTime? startAfter,
  }) {
    throw UnimplementedError();
  }
}

Booking _activeBooking({
  String id = 'booking-1',
  DateTime? slotStart,
  DateTime? slotEnd,
  AppointmentBookingStatus status = AppointmentBookingStatus.confirmed,
}) {
  final start = slotStart ?? DateTime(2026, 6, 3, 10);
  final end = slotEnd ?? DateTime(2026, 6, 3, 10, 30);

  return Booking(
    id: id,
    clientId: 'client-1',
    barberId: 'barber-1',
    barbershopId: 'shop-1',
    serviceId: 'service-1',
    dateKey: '2026-06-03',
    slotStart: start,
    slotEnd: end,
    status: status,
    price: 5000,
    durationMinutes: 30,
    clientSnapshot: const BookingSnapshot(name: 'Cliente Uno'),
    barberSnapshot: const BookingSnapshot(name: 'Barbero Uno'),
    shopSnapshot: const BookingSnapshot(name: 'Shop Uno'),
    serviceSnapshot: const BookingSnapshot(name: 'Corte'),
  );
}

Booking _inactiveBooking({
  AppointmentBookingStatus status = AppointmentBookingStatus.completed,
  bool reviewed = false,
}) {
  return Booking(
    id: 'booking-inactive',
    clientId: 'client-1',
    barberId: 'barber-1',
    barbershopId: 'shop-1',
    serviceId: 'service-1',
    dateKey: '2026-06-03',
    slotStart: DateTime(2026, 6, 3, 11),
    slotEnd: DateTime(2026, 6, 3, 11, 30),
    status: status,
    price: 5000,
    durationMinutes: 30,
    clientSnapshot: const BookingSnapshot(name: 'Cliente Uno'),
    barberSnapshot: const BookingSnapshot(name: 'Barbero Uno'),
    shopSnapshot: const BookingSnapshot(name: 'Shop Uno'),
    serviceSnapshot: const BookingSnapshot(name: 'Corte'),
    reviewId: reviewed ? 'review-1' : null,
    reviewedAt: reviewed ? DateTime(2026, 6, 3, 12) : null,
  );
}

Booking _cancelledWithPenaltyBooking() {
  return Booking(
    id: 'booking-penalty',
    clientId: 'client-1',
    barberId: 'barber-1',
    barbershopId: 'shop-1',
    serviceId: 'service-1',
    dateKey: '2026-06-03',
    slotStart: DateTime(2026, 6, 2, 10),
    slotEnd: DateTime(2026, 6, 2, 10, 30),
    status: AppointmentBookingStatus.cancelled,
    price: 5000,
    durationMinutes: 30,
    clientSnapshot: const BookingSnapshot(name: 'Cliente Uno'),
    barberSnapshot: const BookingSnapshot(name: 'Barbero Uno'),
    shopSnapshot: const BookingSnapshot(name: 'Shop Uno'),
    serviceSnapshot: const BookingSnapshot(name: 'Corte'),
    cancelledBy: BookingCancellationActor.client,
    cancelledAt: DateTime(2026, 6, 2, 9, 15),
    cancellationReason: 'No llego a tiempo',
    penaltyApplied: true,
    penaltyAmount: 2500,
  );
}

Booking _cancelledWithoutPenaltyBooking() {
  return Booking(
    id: 'booking-cancelled',
    clientId: 'client-1',
    barberId: 'barber-1',
    barbershopId: 'shop-1',
    serviceId: 'service-1',
    dateKey: '2026-06-03',
    slotStart: DateTime(2026, 6, 1, 14),
    slotEnd: DateTime(2026, 6, 1, 14, 30),
    status: AppointmentBookingStatus.cancelled,
    price: 5000,
    durationMinutes: 30,
    clientSnapshot: const BookingSnapshot(name: 'Cliente Uno'),
    barberSnapshot: const BookingSnapshot(name: 'Barbero Uno'),
    shopSnapshot: const BookingSnapshot(name: 'Shop Uno'),
    serviceSnapshot: const BookingSnapshot(name: 'Corte'),
    cancelledBy: BookingCancellationActor.barber,
    cancelledAt: DateTime(2026, 6, 1, 12),
    cancellationReason: 'Emergencia personal',
  );
}
