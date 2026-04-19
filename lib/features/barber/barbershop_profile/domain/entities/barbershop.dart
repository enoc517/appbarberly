import 'barber.dart';
import 'service.dart';
import 'time_slot.dart';

class Barbershop {
  final String id;
  final String name;
  final String district;
  final String? heroImageUrl;
  final List<Service> services;
  final List<Barber> barbers;
  final Map<DateTime, List<TimeSlot>> slotsByDay;

  const Barbershop({
    required this.id,
    required this.name,
    required this.district,
    this.heroImageUrl,
    required this.services,
    required this.barbers,
    required this.slotsByDay,
  });

  List<DateTime> get availableDays =>
      slotsByDay.keys.toList()..sort((a, b) => a.compareTo(b));

  List<TimeSlot> slotsFor(DateTime day) => slotsByDay[day] ?? const [];
}