import '../entities/booking.dart';

abstract class BookingsRepository {
  Future<String> createBooking(BookingDraft draft);

  Future<void> cancelBooking({
    required String bookingId,
    required String clientId,
    required BookingCancellationActor cancelledBy,
    String? cancellationReason,
  });

  Future<void> rescheduleBooking({
    required String bookingId,
    required BookingDraft draft,
  });

  Future<void> completeBooking({
    required String bookingId,
    required String clientId,
  });

  Stream<List<Booking>> watchClientBookings(String clientId);

  Stream<List<Booking>> watchBarberAgenda({
    required String barbershopId,
    required String barberId,
    required String dateKey,
  });

  Stream<List<Booking>> watchBarbershopBookings({
    required String barbershopId,
    required DateTime start,
    required DateTime end,
  });
}
