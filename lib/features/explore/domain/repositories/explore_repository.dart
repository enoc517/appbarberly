// lib/features/explore/domain/repositories/explore_repository.dart
//
// Contrato abstracto del repositorio de Explorar.
//
// Esta interfaz pertenece a la capa de DOMINIO: define QUÉ se puede hacer,
// sin mencionar CÓMO se hace. La implementación concreta vive en la capa
// de datos (ExploreRepositoryImpl) e inyecta esta interfaz mediante DI.
//
// Principio aplicado: Inversión de Dependencias (SOLID — D)
//   · El BLoC depende de ExploreRepository (abstracción).
//   · ExploreRepositoryImpl depende de ExploreRepository (abstracción).
//   · Ninguna capa de dominio o presentación importa la implementación.
// ===========================================================================

import 'package:geolocator/geolocator.dart';

import 'package:barberly/features/explore/domain/entities/explore_entities.dart';

abstract class ExploreRepository {
  // ── Barberías ─────────────────────────────────────────────────────────────

  /// Stream de barberías dentro de [radiusKm] desde [lat],[lng].
  /// geoflutterfire_plus retorna resultados ordenados por cercanía.
  Stream<List<BarbershopEntity>> getNearbyBarbershops({
    required double lat,
    required double lng,
    double radiusKm = 10.0,
  });

  // ── Servicios ─────────────────────────────────────────────────────────────

  /// Stream de servicios cercanos con datos de barbería denormalizados.
  /// Pasar [category] para filtrar; null = todos.
  Stream<List<ServiceExploreEntity>> getNearbyServices({
    required double lat,
    required double lng,
    double radiusKm = 10.0,
    String? category,
  });

  // ── Favoritos ─────────────────────────────────────────────────────────────

  /// Stream de IDs de barberías favoritas del usuario.
  /// Emite [] si la subcolección está vacía → el BLoC emite estado vacío.
  Stream<List<String>> getUserFavoriteIds(String userId);

  /// Agrega o elimina una barbería de favoritos.
  Future<void> toggleFavorite({
    required String userId,
    required String barbershopId,
    required bool isCurrentlyFavorite,
  });

  // ── Geolocalización ───────────────────────────────────────────────────────

  /// Solicita permisos y retorna la posición actual del usuario.
  /// Lanza [LocationPermissionDeniedException] si el usuario rechaza.
  Future<Position> getCurrentPosition();
}