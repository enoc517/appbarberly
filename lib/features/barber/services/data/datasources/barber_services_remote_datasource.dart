import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/barber_service.dart';
import '../../domain/entities/barber_schedule.dart';

abstract class BarberServicesRemoteDatasource {
  Future<List<BarberService>> getServices(
    String barbershopId,
    String barberId,
  );
  Future<BarberService> addService({
    required String barbershopId,
    required String barberId,
    required String name,
    required String description,
    required double price,
    required int durationMinutes,
    required String category,
  });
  Future<BarberService> updateService({
    required String barbershopId,
    required String barberId,
    required String serviceId,
    String? name,
    String? description,
    double? price,
    int? durationMinutes,
    String? category,
    bool? isActive,
  });
  Future<void> deleteService({
    required String barbershopId,
    required String barberId,
    required String serviceId,
  });
  Future<List<BarberSchedule>> getSchedule(
    String barbershopId,
    String barberId,
  );
  Future<void> setSchedule({
    required String barbershopId,
    required String barberId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required bool isActive,
  });
}

class BarberServicesRemoteDatasourceImpl
    implements BarberServicesRemoteDatasource {
  BarberServicesRemoteDatasourceImpl({
    FirebaseFirestore? firestore,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _servicesCollection(
    String barbershopId,
    String barberId,
  ) => _db
          .collection('barbershops')
          .doc(barbershopId)
          .collection('barbers')
          .doc(barberId)
          .collection('services');

  CollectionReference<Map<String, dynamic>> _scheduleCollection(
    String barbershopId,
    String barberId,
  ) => _db
          .collection('barbershops')
          .doc(barbershopId)
          .collection('barbers')
          .doc(barberId)
          .collection('schedule');

  @override
  Future<List<BarberService>> getServices(
    String barbershopId,
    String barberId,
  ) async {
    final snapshot = await _servicesCollection(barbershopId, barberId)
        .orderBy('name')
        .get();
    return snapshot.docs.map(_mapService).toList();
  }

  @override
  Future<BarberService> addService({
    required String barbershopId,
    required String barberId,
    required String name,
    required String description,
    required double price,
    required int durationMinutes,
    required String category,
  }) async {
    final docRef = _servicesCollection(barbershopId, barberId).doc();
    final data = <String, dynamic>{
      'name': name,
      'description': description,
      'price': price,
      'durationMinutes': durationMinutes,
      'category': category,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    };
    await docRef.set(data);
    return BarberService(
      id: docRef.id,
      name: name,
      description: description,
      price: price,
      durationMinutes: durationMinutes,
      category: category,
      isActive: true,
    );
  }

  @override
  Future<BarberService> updateService({
    required String barbershopId,
    required String barberId,
    required String serviceId,
    String? name,
    String? description,
    double? price,
    int? durationMinutes,
    String? category,
    bool? isActive,
  }) async {
    final docRef =
        _servicesCollection(barbershopId, barberId).doc(serviceId);
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (price != null) data['price'] = price;
    if (durationMinutes != null) data['durationMinutes'] = durationMinutes;
    if (category != null) data['category'] = category;
    if (isActive != null) data['isActive'] = isActive;
    data['updatedAt'] = FieldValue.serverTimestamp();

    await docRef.set(data, SetOptions(merge: true));
    final updated = await docRef.get();
    return _mapService(updated);
  }

  @override
  Future<void> deleteService({
    required String barbershopId,
    required String barberId,
    required String serviceId,
  }) async {
    await _servicesCollection(barbershopId, barberId).doc(serviceId).delete();
  }

  @override
  Future<List<BarberSchedule>> getSchedule(
    String barbershopId,
    String barberId,
  ) async {
    final snapshot = await _scheduleCollection(barbershopId, barberId)
        .orderBy('dayOfWeek')
        .get();
    return snapshot.docs.map(_mapSchedule).toList();
  }

  @override
  Future<void> setSchedule({
    required String barbershopId,
    required String barberId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required bool isActive,
  }) async {
    final docId = 'day_$dayOfWeek';
    final data = <String, dynamic>{
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _scheduleCollection(barbershopId, barberId)
        .doc(docId)
        .set(data, SetOptions(merge: true));
  }

  BarberService _mapService(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return BarberService(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: data['durationMinutes'] as int? ?? 0,
      category: data['category'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  BarberSchedule _mapSchedule(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return BarberSchedule(
      id: doc.id,
      dayOfWeek: data['dayOfWeek'] as int? ?? 0,
      startTime: data['startTime'] as String? ?? '',
      endTime: data['endTime'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? false,
    );
  }
}
