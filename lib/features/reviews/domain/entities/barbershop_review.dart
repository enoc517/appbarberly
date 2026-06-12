import '../../../bookings/domain/entities/booking.dart';

class BarbershopReview {
  const BarbershopReview({
    required this.id,
    required this.bookingId,
    required this.clientId,
    required this.barberId,
    required this.barbershopId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.clientSnapshot,
    required this.barberSnapshot,
    required this.serviceSnapshot,
  });

  final String id;
  final String bookingId;
  final String clientId;
  final String barberId;
  final String barbershopId;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final BookingSnapshot clientSnapshot;
  final BookingSnapshot barberSnapshot;
  final BookingSnapshot serviceSnapshot;
}
