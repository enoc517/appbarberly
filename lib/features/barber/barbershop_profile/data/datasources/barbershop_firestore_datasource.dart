import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/time_slot.dart';
import '../models/barber_model.dart';
import '../models/barbershop_model.dart';
import '../models/service_model.dart';
import '../models/time_slot_model.dart';

/// Data source que lee del Firestore real.
class BarbershopFirestoreDataSource {
  BarbershopFirestoreDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Carga un barbershop completo (header + servicios + barberos + slots de 14 días).
  Future<BarbershopDto> getBarbershop(String barbershopId) async {
    final shopRef = _firestore.collection('barbershops').doc(barbershopId);

    final today = DateTime.now();
    final todayKey = _dateKey(DateTime(today.year, today.month, today.day));
    final in14DaysKey = _dateKey(
      DateTime(today.year, today.month, today.day).add(const Duration(days: 14)),
    );

    final results = await Future.wait([
      shopRef.get(),
      shopRef.collection('services').get(),
      shopRef.collection('barbers').where('active', isEqualTo: true).get(),
      shopRef
          .collection('slots')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: todayKey)
          .where(FieldPath.documentId, isLessThanOrEqualTo: in14DaysKey)
          .get(),
    ]);

    final shopDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    if (!shopDoc.exists) {
      throw StateError('Barbershop $barbershopId no existe en Firestore');
    }

    final servicesSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final barbersSnap = results[2] as QuerySnapshot<Map<String, dynamic>>;
    final slotsSnap = results[3] as QuerySnapshot<Map<String, dynamic>>;

    final services = servicesSnap.docs.map(ServiceModel.fromFirestore).toList();
    final barbers = barbersSnap.docs.map(BarberModel.fromFirestore).toList();
    final slotsByDay = _parseSlots(slotsSnap.docs);

    final shopModel = BarbershopModel.fromFirestore(shopDoc);

    return BarbershopDto(
      shop: shopModel,
      services: services,
      barbers: barbers,
      slotsByDay: slotsByDay,
    );
  }

  /// Marca el slot como 'booked' y crea un booking en /bookings. Atómico via transacción.
  Future<void> confirmBooking({
    required String barbershopId,
    required String serviceId,
    required String barberId,
    required DateTime slotStartTime,
    required int durationMinutes,
    required double price,
    String? clientId,
  }) async {
    final dayKey = _dateKey(slotStartTime);
    final slotDocRef = _firestore
        .collection('barbershops')
        .doc(barbershopId)
        .collection('slots')
        .doc(dayKey);
    final bookingRef = _firestore.collection('bookings').doc();

    await _firestore.runTransaction((txn) async {
      final slotDoc = await txn.get(slotDocRef);
      if (!slotDoc.exists) {
        throw StateError('No hay slots configurados para $dayKey');
      }

      final data = slotDoc.data() ?? const <String, dynamic>{};
      final rawTimes = (data['times'] as List<dynamic>? ?? const []);

      var changed = false;
      final updated = rawTimes.map<Map<String, dynamic>>((entry) {
        final map = Map<String, dynamic>.from(entry as Map);
        final slotStart = DateTime.parse(map['startTime'] as String);
        if (slotStart.isAtSameMomentAs(slotStartTime)) {
          if (map['status'] != SlotStatus.available.name) {
            throw StateError('El slot ya no está disponible');
          }
          map['status'] = SlotStatus.booked.name;
          changed = true;
        }
        return map;
      }).toList();

      if (!changed) {
        throw StateError('No se encontró el slot para $slotStartTime');
      }

      txn.update(slotDocRef, {'times': updated});
      txn.set(bookingRef, {
        'barbershopId': barbershopId,
        'barberId': barberId,
        'serviceId': serviceId,
        'clientId': clientId,
        'startTime': Timestamp.fromDate(slotStartTime),
        'durationMinutes': durationMinutes,
        'price': price,
        'status': 'confirmed',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ---- helpers privados ----

  Map<DateTime, List<TimeSlot>> _parseSlots(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final result = <DateTime, List<TimeSlot>>{};
    for (final doc in docs) {
      final day = _parseDateKey(doc.id);
      if (day == null) continue;

      final data = doc.data();
      final rawTimes = (data['times'] as List<dynamic>? ?? const []);
      final slots = rawTimes
          .map((e) => TimeSlotModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .map((m) => m.toEntity())
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      result[day] = slots;
    }
    return result;
  }

  String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  DateTime? _parseDateKey(String id) {
    try {
      final parts = id.split('-');
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return null;
    }
  }
}

/// DTO interno que agrupa lo que devuelve getBarbershop.
class BarbershopDto {
  const BarbershopDto({
    required this.shop,
    required this.services,
    required this.barbers,
    required this.slotsByDay,
  });

  final BarbershopModel shop;
  final List<ServiceModel> services;
  final List<BarberModel> barbers;
  final Map<DateTime, List<TimeSlot>> slotsByDay;
}