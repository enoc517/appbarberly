import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/barbershop.dart';
import '../../domain/entities/time_slot.dart';
import 'barber_model.dart';
import 'service_model.dart';

class BarbershopModel {
  const BarbershopModel({
    required this.id,
    required this.name,
    required this.district,
    required this.heroImageUrl,
    required this.ownerId,
  });

  final String id;
  final String name;
  final String district;
  final String heroImageUrl;
  final String ownerId;

  factory BarbershopModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return BarbershopModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      district: data['district'] as String? ?? '',
      heroImageUrl: data['heroImageUrl'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'district': district,
        'heroImageUrl': heroImageUrl,
        'ownerId': ownerId,
      };

  /// Construye la entity ensamblando los pedazos que cargó el datasource.
  Barbershop toEntity({
    required List<ServiceModel> services,
    required List<BarberModel> barbers,
    required Map<DateTime, List<TimeSlot>> slotsByDay,
  }) {
    return Barbershop(
      id: id,
      name: name,
      district: district,
      heroImageUrl: heroImageUrl,
      ownerId: ownerId,
      services: services.map((s) => s.toEntity()).toList(),
      barbers: barbers.map((b) => b.toEntity()).toList(),
      slotsByDay: slotsByDay,
    );
  }
}