// lib/features/explore/presentation/bloc/service_model.dart
//
// Modelo de presentación para la ServiceCard.
// Vive en la capa de presentación — no es una entidad de dominio.
// Se construye mapeando ServiceExploreEntity desde el BLoC o
// usando el extension ServiceExploreEntityX.toServiceModel().
// ===========================================================================

class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.barbershopId,
    required this.name,
    required this.shopName,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.price,
    required this.distance,
    required this.category,
    this.isNew = false,
    this.isAvailable = true,
  });

  final String id;
  final String barbershopId;

  /// Nombre del servicio — mostrado en el título de la card.
  final String name;

  /// Nombre de la barbería — subtítulo de la card.
  final String shopName;

  /// URL de la imagen de portada (usa barbershopSnapshot.imageUrl).
  final String imageUrl;

  /// Rating promedio de la barbería (barbershopSnapshot.rating).
  final double rating;

  /// Total de reseñas de la barbería.
  final int reviewCount;

  /// Precio formateado como string, ej. "₡6.500".
  final String price;

  /// Distancia formateada como string, ej. "1.2 km".
  final String distance;

  /// Categoría: 'corte' | 'barba' | 'combo' | 'tratamiento'.
  final String category;

  /// Muestra el badge "ear notch" de nuevo servicio.
  final bool isNew;

  /// Controla el overlay de "No disponible".
  final bool isAvailable;
}
