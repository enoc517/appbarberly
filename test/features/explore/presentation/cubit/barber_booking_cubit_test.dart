import 'package:barberly/core/events/barbershop_event_bus.dart';
import 'package:barberly/features/bookings/domain/entities/booking.dart';
import 'package:barberly/features/client/favorites/domain/entities/favorite_barbershop_entry.dart';
import 'package:barberly/features/client/favorites/domain/repositories/favorites_repository.dart';
import 'package:barberly/features/explore/domain/repositories/barber_booking_repository.dart';
import 'package:barberly/features/explore/presentation/cubit/barber_booking_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BarberBookingCubit', () {
    late _FakeBarberBookingRepository bookingRepository;
    late _FakeFavoritesRepository favoritesRepository;
    late BarberBookingCubit cubit;

    setUp(() {
      bookingRepository = _FakeBarberBookingRepository();
      favoritesRepository = _FakeFavoritesRepository();
      cubit = BarberBookingCubit(
        shopId: 'shop-1',
        barberId: 'barber-1',
        clientId: 'client-1',
        repository: bookingRepository,
        favoritesRepository: favoritesRepository,
        eventBus: BarbershopEventBus.instance,
      );
      cubit.selectService({'id': 'service-1', 'name': 'Corte', 'price': 5000});
      cubit.selectDay(DateTime(2026, 6, 3));
    });

    tearDown(() async {
      await cubit.close();
    });

    test(
      'evaluateFavoriteSuggestion asks to prompt when not favorite',
      () async {
        final result = await cubit.evaluateFavoriteSuggestion();

        expect(result, FavoriteSuggestionStatus.shouldPrompt);
        expect(favoritesRepository.calls, ['isFavorite:client-1:shop-1']);
      },
    );

    test(
      'evaluateFavoriteSuggestion records usage when already favorite',
      () async {
        favoritesRepository.isFavoriteResult = true;

        final result = await cubit.evaluateFavoriteSuggestion();

        expect(result, FavoriteSuggestionStatus.alreadyFavoriteRecorded);
        expect(favoritesRepository.calls, [
          'isFavorite:client-1:shop-1',
          'record:client-1:shop-1:service-1:Corte:barber-1:Barbero',
        ]);
      },
    );

    test('addFavoriteSuggestion delegates to addFavorite', () async {
      await cubit.addFavoriteSuggestion();

      expect(favoritesRepository.calls, [
        'add:client-1:shop-1:2026-06-03 00:00:00.000:service-1:Corte:barber-1:null:1',
      ]);
    });

    test('evaluateFavoriteSuggestion skips reschedules', () async {
      cubit = BarberBookingCubit(
        shopId: 'shop-1',
        barberId: 'barber-1',
        clientId: 'client-1',
        rescheduleBooking: _booking(),
        repository: bookingRepository,
        favoritesRepository: favoritesRepository,
        eventBus: BarbershopEventBus.instance,
      )..selectService({'id': 'service-1', 'name': 'Corte', 'price': 5000});

      final result = await cubit.evaluateFavoriteSuggestion();

      expect(result, FavoriteSuggestionStatus.skipped);
      expect(favoritesRepository.calls, isEmpty);
    });
  });
}

class _FakeBarberBookingRepository implements BarberBookingRepository {
  @override
  Future<void> createBooking(BookingDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<String> getClientName(String clientId) {
    throw UnimplementedError();
  }

  @override
  Future<String> getShopName(String shopId) {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> loadAvailableTimeSlots({
    required String shopId,
    required String barberId,
    required DateTime day,
    required int durationMinutes,
    String? excludeBookingId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<BarberBookingData> loadBarberData(String shopId, String barberId) {
    throw UnimplementedError();
  }

  @override
  Future<void> rescheduleBooking({
    required String bookingId,
    required BookingDraft draft,
  }) {
    throw UnimplementedError();
  }
}

class _FakeFavoritesRepository implements FavoritesRepository {
  final calls = <String>[];
  bool isFavoriteResult = false;

  @override
  Future<void> addFavorite({
    required String userId,
    required String barbershopId,
    DateTime? lastBookedAt,
    String? lastServiceId,
    String? lastServiceName,
    String? lastBarberId,
    String? lastBarberName,
    int? bookingCount,
  }) async {
    calls.add(
      'add:$userId:$barbershopId:$lastBookedAt:$lastServiceId:$lastServiceName:$lastBarberId:$lastBarberName:$bookingCount',
    );
  }

  @override
  Future<bool> isFavorite(String userId, String barbershopId) async {
    calls.add('isFavorite:$userId:$barbershopId');
    return isFavoriteResult;
  }

  @override
  Stream<List<FavoriteBarbershopEntry>> watchFavoriteBarbershops(
    String userId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> recordFavoriteBooking({
    required String userId,
    required String barbershopId,
    required DateTime bookedAt,
    required String serviceId,
    required String serviceName,
    required String barberId,
    required String barberName,
  }) async {
    calls.add(
      'record:$userId:$barbershopId:$serviceId:$serviceName:$barberId:$barberName',
    );
  }
}

Booking _booking() {
  return Booking(
    id: 'booking-1',
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
