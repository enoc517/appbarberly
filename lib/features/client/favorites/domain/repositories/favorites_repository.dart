import '../entities/favorite_barbershop_entry.dart';

abstract class FavoritesRepository {
  Stream<List<FavoriteBarbershopEntry>> watchFavoriteBarbershops(String userId);

  Future<bool> isFavorite(String userId, String barbershopId);

  Future<void> addFavorite({
    required String userId,
    required String barbershopId,
    DateTime? lastBookedAt,
    String? lastServiceId,
    String? lastServiceName,
    String? lastBarberId,
    String? lastBarberName,
    int? bookingCount,
  });

  Future<void> recordFavoriteBooking({
    required String userId,
    required String barbershopId,
    required DateTime bookedAt,
    required String serviceId,
    required String serviceName,
    required String barberId,
    required String barberName,
  });
}
