import '../../domain/entities/time_slot.dart';

class TimeSlotModel {
  const TimeSlotModel({
    required this.startTime,
    required this.status,
  });

  final DateTime startTime;
  final SlotStatus status;

  factory TimeSlotModel.fromMap(Map<String, dynamic> map) {
    return TimeSlotModel(
      startTime: DateTime.parse(map['startTime'] as String),
      status: _parseStatus(map['status'] as String?),
    );
  }

  Map<String, dynamic> toMap() => {
        'startTime': startTime.toIso8601String(),
        'status': status.name,
      };

  TimeSlot toEntity() => TimeSlot(
        startTime: startTime,
        status: status,
      );

  static SlotStatus _parseStatus(String? raw) {
    return SlotStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => SlotStatus.available,
    );
  }
}