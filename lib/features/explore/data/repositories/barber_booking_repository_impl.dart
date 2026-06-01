import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../bookings/data/repositories/firestore_bookings_repository.dart';
import '../../../bookings/domain/entities/booking.dart';
import '../../domain/repositories/barber_booking_repository.dart';

class BarberBookingRepositoryImpl implements BarberBookingRepository {
  BarberBookingRepositoryImpl({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<BarberBookingData> loadBarberData(
      String shopId, String barberId) async {
    final memberDoc = await _db
        .collection('barbershops')
        .doc(shopId)
        .collection('members')
        .doc(barberId)
        .get();

    final barberName =
        memberDoc.data()?['barberName'] as String? ?? 'Barbero';

    final servicesSnapshot = await _db
        .collection('barbershops')
        .doc(shopId)
        .collection('barbers')
        .doc(barberId)
        .collection('services')
        .where('isActive', isEqualTo: true)
        .get();

    final scheduleSnapshot = await _db
        .collection('barbershops')
        .doc(shopId)
        .collection('barbers')
        .doc(barberId)
        .collection('schedule')
        .get();

    final services = servicesSnapshot.docs
        .map((d) => {'id': d.id, ...d.data()})
        .toList();

    final schedule = <int, bool>{};
    for (final doc in scheduleSnapshot.docs) {
      final data = doc.data();
      if (data['isActive'] == true) {
        schedule[data['dayOfWeek'] as int] = true;
      }
    }

    return BarberBookingData(
      barberName: barberName,
      services: services,
      schedule: schedule,
    );
  }

  @override
  Future<String> getClientName(String clientId) async {
    final clientDoc = await _db.collection('users').doc(clientId).get();
    return clientDoc.data()?['fullName'] as String? ?? 'Cliente';
  }

  @override
  Future<String> getShopName(String shopId) async {
    final shopDoc = await _db.collection('barbershops').doc(shopId).get();
    return shopDoc.data()?['name'] as String? ?? '';
  }

  @override
  Future<void> createBooking(BookingDraft draft) async {
    final repository = FirestoreBookingsRepository(firestore: _db);
    await repository.createBooking(draft);
  }
}
