import '../../domain/entities/barber.dart';
import '../../domain/entities/barbershop.dart';
import '../../domain/entities/service.dart';
import '../../domain/entities/time_slot.dart';

/// Fuente de datos en memoria. Reemplazar por FirestoreDataSource
/// o RemoteDataSource cuando se integre backend real.
class BarbershopMockDataSource {
  Future<Barbershop> fetchBarbershop(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    Map<DateTime, List<TimeSlot>> slots = {
      for (int i = 0; i < 4; i++)
        startOfToday.add(Duration(days: i)): _mockSlotsFor(
          startOfToday.add(Duration(days: i)),
        ),
    };

    return Barbershop(
      id: id,
      name: 'Celestial Grooming Lounge',
      district: 'Distrito Galáctico',
      services: const [
        Service(
          id: 'svc-1',
          name: 'Corte Galáctico Superior',
          description: 'Acabado con toalla caliente y ritual de fragancia',
          duration: Duration(minutes: 45),
          price: 35.00,
          featured: true,
        ),
        Service(
          id: 'svc-2',
          name: 'Ritual de Barba Estelar',
          description: 'Delineado con navaja clásica y aceites esenciales',
          duration: Duration(minutes: 30),
          price: 22.00,
        ),
        Service(
          id: 'svc-3',
          name: 'Pack Combo Maestro',
          description: 'Corte completo + Barba + Exfoliación facial',
          duration: Duration(minutes: 75),
          price: 50.00,
        ),
      ],
      barbers: const [
        Barber(id: 'brb-1', name: 'Alejandro V.'),
        Barber(id: 'brb-2', name: 'Marcos R.'),
      ],
      slotsByDay: slots,
    );
  }

  Future<void> confirmBooking() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Simula éxito.
  }

  List<TimeSlot> _mockSlotsFor(DateTime day) {
    TimeSlot at(int h, int m, SlotStatus s) => TimeSlot(
          startTime: DateTime(day.year, day.month, day.day, h, m),
          status: s,
        );
    return [
      at(9, 0, SlotStatus.available),
      at(10, 30, SlotStatus.available),
      at(11, 30, SlotStatus.booked),
      at(13, 0, SlotStatus.available),
      at(15, 30, SlotStatus.available),
      at(16, 30, SlotStatus.waitlist),
    ];
  }
}