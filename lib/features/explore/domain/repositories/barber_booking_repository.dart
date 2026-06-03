import '../../../barber/services/domain/entities/barber_schedule.dart';
import '../../../bookings/domain/entities/booking.dart';

abstract class BarberBookingRepository {
  Future<BarberBookingData> loadBarberData(String shopId, String barberId);
  Future<String> getClientName(String clientId);
  Future<String> getShopName(String shopId);
  Future<List<String>> loadAvailableTimeSlots({
    required String shopId,
    required String barberId,
    required DateTime day,
    required int durationMinutes,
  });
  Future<void> createBooking(BookingDraft draft);
}

class BarberBookingData {
  final String barberName;
  final List<Map<String, dynamic>> services;
  final Map<int, BarberSchedule> schedule;

  const BarberBookingData({
    required this.barberName,
    required this.services,
    required this.schedule,
  });
}
