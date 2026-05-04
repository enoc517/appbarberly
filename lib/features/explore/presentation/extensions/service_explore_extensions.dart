// lib/features/explore/presentation/extensions/service_explore_extensions.dart
//
// Extension sobre ServiceExploreEntity que produce un ServiceModel listo
// para la capa de presentación.
//
// Patrón: el dominio no conoce ServiceModel (no contamina entidades puras).
// La presentación usa este extension para el mapeo sin lógica en la UI.
// ===========================================================================

import 'package:barberly/features/explore/domain/entities/explore_entities.dart';
import 'package:barberly/features/explore/presentation/bloc/service_model.dart';

extension ServiceExploreEntityX on ServiceExploreEntity {
  ServiceModel toServiceModel() {
    return ServiceModel(
      id: id,
      barbershopId: barbershopId,
      name: serviceName,
      shopName: barbershopSnapshot.name,
      imageUrl: barbershopSnapshot.imageUrl,
      rating: barbershopSnapshot.rating,
      // reviewCount no está en el snapshot — usar 0 hasta que se denormalice
      reviewCount: 0,
      // Formatear precio en colones costarricenses
      price: _formatPrice(price),
      // Distancia calculada: si está disponible usarla, si no mostrar vacío
      distance: distanceKm != null
          ? '${distanceKm!.toStringAsFixed(1)} km'
          : '',
      category: category,
      isNew: false,
      isAvailable: true,
    );
  }

  /// Formatea un double como precio CRC: 6500 → "₡6.500"
  static String _formatPrice(double amount) {
    final parts = amount.toInt().toString().split('');
    final buffer = StringBuffer('₡');
    for (var i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) buffer.write('.');
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }
}