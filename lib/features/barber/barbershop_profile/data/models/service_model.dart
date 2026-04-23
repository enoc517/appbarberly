import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/service.dart';

class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.price,
    required this.featured,
  });

  final String id;
  final String name;
  final String description;
  final int durationMinutes;
  final double price;
  final bool featured;

  factory ServiceModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return ServiceModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 30,
      price: (data['price'] as num?)?.toDouble() ?? 0,
      featured: data['featured'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'durationMinutes': durationMinutes,
        'price': price,
        'featured': featured,
      };

  Service toEntity() => Service(
        id: id,
        name: name,
        description: description,
        duration: Duration(minutes: durationMinutes),
        price: price,
        featured: featured,
      );
}