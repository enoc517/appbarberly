// lib/features/explore/data/models/explore_models.dart
//
// Modelos de datos — capa de acceso a Firestore.
// Cada modelo sabe cómo construirse desde un DocumentSnapshot y cómo
// convertirse en su entidad de dominio correspondiente.
//
// Convención: los modelos NO se usan fuera de la capa de datos.
// El repositorio devuelve siempre entidades de dominio, nunca modelos.
// ===========================================================================

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:barberly/features/explore/domain/entities/explore_entities.dart';

// ---------------------------------------------------------------------------
// BarbershopModel
// ---------------------------------------------------------------------------

class BarbershopModel {
  const BarbershopModel({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.phone,
    required this.address,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.hasActivePromotion,
    required this.tags,
    required this.barberNames,
  });

  final String id;
  final String name;
  final String ownerName;
  final String phone;
  final String address;
  final double lat;
  final double lng;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final bool hasActivePromotion;
  final List<String> tags;
  final List<String> barberNames;

  // ── Constructor desde Firestore ──────────────────────────────────────────

  factory BarbershopModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Extraer lat/lng desde el objeto position.geopoint
    final position = data['position'] as Map<String, dynamic>? ?? {};
    final geoPoint = position['geopoint'] as GeoPoint? ?? const GeoPoint(0, 0);

    return BarbershopModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      address: data['address'] as String? ?? '',
      lat: geoPoint.latitude,
      lng: geoPoint.longitude,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      imageUrl: data['imageUrl'] as String? ?? '',
      hasActivePromotion: data['hasActivePromotion'] as bool? ?? false,
      tags: List<String>.from(data['tags'] as List? ?? []),
      barberNames: _barberNamesFromData(data),
    );
  }

  static List<String> _barberNamesFromData(Map<String, dynamic> data) {
    final names = <String>{
      ...List<String>.from(data['barberNames'] as List? ?? []),
    };

    final ownerName = data['ownerName'] as String?;
    if (ownerName != null && ownerName.trim().isNotEmpty) {
      names.add(ownerName.trim());
    }

    return names.toList();
  }

  // ── Conversión a entidad de dominio ─────────────────────────────────────

  BarbershopEntity toEntity() => BarbershopEntity(
    id: id,
    name: name,
    ownerName: ownerName,
    phone: phone,
    address: address,
    lat: lat,
    lng: lng,
    rating: rating,
    reviewCount: reviewCount,
    imageUrl: imageUrl,
    hasActivePromotion: hasActivePromotion,
    tags: tags,
    barberNames: barberNames,
  );
}

// ---------------------------------------------------------------------------
// BarbershopSnapshotModel
// Lee el sub-objeto 'barbershopSnapshot' dentro de services_explore.
// ---------------------------------------------------------------------------

class BarbershopSnapshotModel {
  const BarbershopSnapshotModel({
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.address,
  });

  final String name;
  final String imageUrl;
  final double rating;
  final String address;

  factory BarbershopSnapshotModel.fromMap(Map<String, dynamic> map) {
    return BarbershopSnapshotModel(
      name: map['name'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      address: map['address'] as String? ?? '',
    );
  }

  BarbershopSnapshotEntity toEntity() => BarbershopSnapshotEntity(
    name: name,
    imageUrl: imageUrl,
    rating: rating,
    address: address,
  );
}

// ---------------------------------------------------------------------------
// ServiceExploreModel
// 1 lectura = ServiceCard completa gracias al barbershopSnapshot denormalizado.
// ---------------------------------------------------------------------------

class ServiceExploreModel {
  const ServiceExploreModel({
    required this.id,
    required this.barbershopId,
    required this.barbershopSnapshot,
    required this.serviceName,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.category,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String barbershopId;
  final BarbershopSnapshotModel barbershopSnapshot;
  final String serviceName;
  final String description;
  final double price;
  final int durationMinutes;
  final String category;
  final double lat;
  final double lng;

  // ── Constructor desde Firestore ──────────────────────────────────────────

  factory ServiceExploreModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Lee el snapshot denormalizado — nunca hace join a barbershops
    final snapshotRaw =
        data['barbershopSnapshot'] as Map<String, dynamic>? ?? {};

    final position = data['position'] as Map<String, dynamic>? ?? {};
    final geoPoint = position['geopoint'] as GeoPoint? ?? const GeoPoint(0, 0);

    return ServiceExploreModel(
      id: doc.id,
      barbershopId: data['barbershopId'] as String? ?? '',
      barbershopSnapshot: BarbershopSnapshotModel.fromMap(snapshotRaw),
      serviceName: data['serviceName'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 0,
      category: data['category'] as String? ?? 'corte',
      lat: geoPoint.latitude,
      lng: geoPoint.longitude,
    );
  }

  // ── Conversión a entidad de dominio ─────────────────────────────────────

  ServiceExploreEntity toEntity() => ServiceExploreEntity(
    id: id,
    barbershopId: barbershopId,
    barbershopSnapshot: barbershopSnapshot.toEntity(),
    serviceName: serviceName,
    description: description,
    price: price,
    durationMinutes: durationMinutes,
    category: category,
    lat: lat,
    lng: lng,
  );
}
