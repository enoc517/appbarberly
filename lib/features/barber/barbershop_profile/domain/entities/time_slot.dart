enum SlotStatus { available, booked, waitlist }

class TimeSlot {
  final DateTime startTime;
  final SlotStatus status;

  const TimeSlot({required this.startTime, required this.status});

  bool get isAvailable => status == SlotStatus.available;
  bool get isWaitlist => status == SlotStatus.waitlist;
  bool get isBooked => status == SlotStatus.booked;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimeSlot &&
          other.startTime == startTime &&
          other.status == status);

  @override
  int get hashCode => Object.hash(startTime, status);
}