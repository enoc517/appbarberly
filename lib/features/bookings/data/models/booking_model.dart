import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/booking.dart';

class BookingModel extends Booking {
  const BookingModel({
    required super.id,
    required super.clientId,
    required super.barberId,
    required super.barbershopId,
    required super.serviceId,
    required super.dateKey,
    required super.slotStart,
    required super.slotEnd,
    required super.status,
    required super.price,
    required super.durationMinutes,
    required super.clientSnapshot,
    required super.barberSnapshot,
    required super.shopSnapshot,
    required super.serviceSnapshot,
    super.cancelledBy,
    super.cancelledAt,
    super.cancellationReason,
    super.penaltyApplied,
    super.penaltyAmount,
    super.reviewId,
    super.reviewedAt,
  });

  factory BookingModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return BookingModel(
      id: doc.id,
      clientId: data['clientId'] as String? ?? '',
      barberId: data['barberId'] as String? ?? '',
      barbershopId: data['barbershopId'] as String? ?? '',
      serviceId: data['serviceId'] as String? ?? '',
      dateKey: data['dateKey'] as String? ?? '',
      slotStart: _dateTime(data['slotStart']),
      slotEnd: _dateTime(data['slotEnd']),
      status: _status(data['status'] as String?),
      price: (data['price'] as num?)?.toDouble() ?? 0,
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 0,
      clientSnapshot: _snapshot(data['clientSnapshot']),
      barberSnapshot: _snapshot(data['barberSnapshot']),
      shopSnapshot: _snapshot(data['shopSnapshot']),
      serviceSnapshot: _snapshot(data['serviceSnapshot']),
      cancelledBy: _cancelledBy(data['cancelledBy'] as String?),
      cancelledAt: _dateTimeOrNull(data['cancelledAt']),
      cancellationReason: data['cancellationReason'] as String?,
      penaltyApplied: data['penaltyApplied'] as bool? ?? false,
      penaltyAmount: (data['penaltyAmount'] as num?)?.toDouble() ?? 0,
      reviewId: data['reviewId'] as String?,
      reviewedAt: _dateTimeOrNull(data['reviewedAt']),
    );
  }

  static DateTime _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static AppointmentBookingStatus _status(String? value) {
    return AppointmentBookingStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => AppointmentBookingStatus.pending,
    );
  }

  static BookingSnapshot _snapshot(Object? value) {
    final map = value is Map<String, dynamic> ? value : <String, dynamic>{};
    return BookingSnapshot(
      name: map['name'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
    );
  }

  static BookingCancellationActor? _cancelledBy(String? value) {
    if (value == null) return null;
    return BookingCancellationActor.values.firstWhere(
      (actor) => actor.name == value,
      orElse: () => BookingCancellationActor.client,
    );
  }

  static DateTime? _dateTimeOrNull(Object? value) {
    if (value == null) return null;
    return _dateTime(value);
  }
}
