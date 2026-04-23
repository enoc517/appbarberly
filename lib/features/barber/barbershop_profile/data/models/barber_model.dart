import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/barber.dart';

class BarberModel {
  const BarberModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.active,
  });

  final String id;
  final String name;
  final String avatarUrl;
  final bool active;

  factory BarberModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return BarberModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String? ?? '',
      active: data['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'avatarUrl': avatarUrl,
        'active': active,
      };

  Barber toEntity() => Barber(
        id: id,
        name: name,
        avatarUrl: avatarUrl,
      );
}