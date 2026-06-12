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
    String? excludeBookingId,
  });
  Future<void> createBooking(BookingDraft draft);
  Future<void> rescheduleBooking({
    required String bookingId,
    required BookingDraft draft,
  });
}

class BarberBookingData {
  final String barberName;
  final String? barberAvatarUrl;
  final List<Map<String, dynamic>> services;
  final Map<int, BarberSchedule> schedule;

  const BarberBookingData({
    required this.barberName,
    this.barberAvatarUrl,
    required this.services,
    required this.schedule,
  });
}
