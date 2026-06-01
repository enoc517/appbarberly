// lib/features/explore/domain/entities/explore_entities.dart
//
// Entidades puras de dominio para la feature de Explorar.
// Sin dependencias de Flutter, Firebase ni ningún framework externo.
// Sigue el principio de Inversión de Dependencias: las capas superiores
// dependen de estas abstracciones, nunca al revés.
// ===========================================================================

import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// ExploreSort
// Definido aquí (dominio) para que BLoC, UI y repositorio compartan
// el mismo tipo sin crear dependencias cruzadas entre capas.
// ---------------------------------------------------------------------------

enum ExploreSort {
  /// geoflutterfire_plus retorna los resultados ordenados por cercanía.
  cercania,

  /// Ordenamiento en cliente: mayor rating primero.
  calificacion,

  /// Ordenamiento en cliente: barberías con promo primero, luego por rating.
  conOferta,
}

// ---------------------------------------------------------------------------
// BarbershopEntity
// ---------------------------------------------------------------------------

class BarbershopEntity extends Equatable {
  const BarbershopEntity({
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
    this.barberNames = const [],
    this.distanceKm,
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

  /// Cuando true, el BLoC indica a MarkerUtils que use el pin ⚡ (Lilo Red).
  final bool hasActivePromotion;

  final List<String> tags;
  final List<String> barberNames;

  /// Distancia calculada en cliente respecto a la posición del usuario.
  /// Es null si aún no se conoce la ubicación del usuario.
  final double? distanceKm;

  BarbershopEntity copyWith({
    String? id,
    String? name,
    String? ownerName,
    String? phone,
    String? address,
    double? lat,
    double? lng,
    double? rating,
    int? reviewCount,
    String? imageUrl,
    bool? hasActivePromotion,
    List<String>? tags,
    List<String>? barberNames,
    double? distanceKm,
  }) {
    return BarbershopEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      imageUrl: imageUrl ?? this.imageUrl,
      hasActivePromotion: hasActivePromotion ?? this.hasActivePromotion,
      tags: tags ?? this.tags,
      barberNames: barberNames ?? this.barberNames,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    ownerName,
    phone,
    address,
    lat,
    lng,
    rating,
    reviewCount,
    imageUrl,
    hasActivePromotion,
    tags,
    barberNames,
    distanceKm,
  ];
}

// ---------------------------------------------------------------------------
// BarbershopSnapshotEntity
// Datos denormalizados guardados DENTRO de services_explore.
// 1 lectura del documento de servicio = datos suficientes para la card.
// ---------------------------------------------------------------------------

class BarbershopSnapshotEntity extends Equatable {
  const BarbershopSnapshotEntity({
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.address,
  });

  final String name;
  final String imageUrl;
  final double rating;
  final String address;

  @override
  List<Object?> get props => [name, imageUrl, rating, address];
}

// ---------------------------------------------------------------------------
// ServiceExploreEntity
// Servicio con snapshot de barbería incluido.
// La ServiceCard usa ÚNICAMENTE esta entidad — nunca vuelve a leer barbershops.
// ---------------------------------------------------------------------------

class ServiceExploreEntity extends Equatable {
  const ServiceExploreEntity({
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
    this.distanceKm,
  });

  final String id;
  final String barbershopId;

  /// Snapshot denormalizado — NO realizar query adicional a barbershops.
  final BarbershopSnapshotEntity barbershopSnapshot;

  final String serviceName;
  final String description;

  /// Precio en colones costarricenses (CRC).
  final double price;

  final int durationMinutes;

  /// 'corte' | 'barba' | 'combo' | 'tratamiento'
  final String category;

  final double lat;
  final double lng;
  final double? distanceKm;

  @override
  List<Object?> get props => [
    id,
    barbershopId,
    barbershopSnapshot,
    serviceName,
    description,
    price,
    durationMinutes,
    category,
    lat,
    lng,
    distanceKm,
  ];
}
