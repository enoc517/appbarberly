enum AppointmentBookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
}

extension AppointmentBookingStatusX on AppointmentBookingStatus {
  bool get isActive =>
      this == AppointmentBookingStatus.pending ||
      this == AppointmentBookingStatus.confirmed ||
      this == AppointmentBookingStatus.inProgress;

  String get label => switch (this) {
    AppointmentBookingStatus.pending => 'Pendiente',
    AppointmentBookingStatus.confirmed => 'Confirmada',
    AppointmentBookingStatus.inProgress => 'En curso',
    AppointmentBookingStatus.completed => 'Completada',
    AppointmentBookingStatus.cancelled => 'Cancelada',
  };
}

class BookingSnapshot {
  const BookingSnapshot({required this.name, this.imageUrl});

  final String name;
  final String? imageUrl;
}

class Booking {
  const Booking({
    required this.id,
    required this.clientId,
    required this.barberId,
    required this.barbershopId,
    required this.serviceId,
    required this.dateKey,
    required this.slotStart,
    required this.slotEnd,
    required this.status,
    required this.price,
    required this.durationMinutes,
    required this.clientSnapshot,
    required this.barberSnapshot,
    required this.shopSnapshot,
    required this.serviceSnapshot,
  });

  final String id;
  final String clientId;
  final String barberId;
  final String barbershopId;
  final String serviceId;
  final String dateKey;
  final DateTime slotStart;
  final DateTime slotEnd;
  final AppointmentBookingStatus status;
  final double price;
  final int durationMinutes;
  final BookingSnapshot clientSnapshot;
  final BookingSnapshot barberSnapshot;
  final BookingSnapshot shopSnapshot;
  final BookingSnapshot serviceSnapshot;

  bool get isActive => status.isActive;
}

class BookingDraft {
  const BookingDraft({
    required this.clientId,
    required this.barberId,
    required this.barbershopId,
    required this.serviceId,
    required this.dateKey,
    required this.slotStart,
    required this.slotEnd,
    required this.price,
    required this.durationMinutes,
    required this.clientSnapshot,
    required this.barberSnapshot,
    required this.shopSnapshot,
    required this.serviceSnapshot,
    this.slotPath,
  });

  final String clientId;
  final String barberId;
  final String barbershopId;
  final String serviceId;
  final String dateKey;
  final DateTime slotStart;
  final DateTime slotEnd;
  final double price;
  final int durationMinutes;
  final BookingSnapshot clientSnapshot;
  final BookingSnapshot barberSnapshot;
  final BookingSnapshot shopSnapshot;
  final BookingSnapshot serviceSnapshot;
  final String? slotPath;
}
