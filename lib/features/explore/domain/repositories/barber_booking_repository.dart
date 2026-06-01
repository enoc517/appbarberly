import '../../../bookings/domain/entities/booking.dart';

abstract class BarberBookingRepository {
  Future<BarberBookingData> loadBarberData(String shopId, String barberId);
  Future<String> getClientName(String clientId);
  Future<String> getShopName(String shopId);
  Future<void> createBooking(BookingDraft draft);
}

class BarberBookingData {
  final String barberName;
  final List<Map<String, dynamic>> services;
  final Map<int, bool> schedule;

  const BarberBookingData({
    required this.barberName,
    required this.services,
    required this.schedule,
  });
}
