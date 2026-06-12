// lib/features/explore/data/repositories/explore_repository_impl.dart
//
// Implementación concreta del repositorio de Explorar.
//
// La interfaz ExploreRepository vive en domain/ — este archivo solo
// contiene la implementación + las excepciones de geolocalización.
//
// DEPENDENCIAS REQUERIDAS en pubspec.yaml:
//   geoflutterfire_plus: ^0.0.34
//   geolocator: ^13.0.2
//   google_maps_flutter: ^2.9.0
//
// ÍNDICES FIRESTORE REQUERIDOS (firestore.indexes.json):
//   barbershops:      [position.geohash ASC, isActive ASC]
//   services_explore: [position.geohash ASC, isActive ASC]
//   services_explore: [position.geohash ASC, category ASC, isActive ASC]
// ===========================================================================

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';

import 'package:barberly/features/explore/data/models/explore_models.dart';
import 'package:barberly/features/explore/domain/entities/explore_entities.dart';
import 'package:barberly/features/explore/domain/repositories/explore_repository.dart';

// ════════════════════════════════════════════════════════════════════════════
// EXCEPCIONES DE DOMINIO
// Declaradas aquí porque son consecuencia de la implementación concreta
// (geolocator). El BLoC las captura por tipo — no por string.
// ════════════════════════════════════════════════════════════════════════════

class LocationServiceDisabledException implements Exception {
  const LocationServiceDisabledException();

  @override
  String toString() =>
      'El servicio de ubicación está desactivado. Actívalo en la configuración del dispositivo.';
}

class LocationPermissionDeniedException implements Exception {
  const LocationPermissionDeniedException();

  @override
  String toString() =>
      'Permiso de ubicación denegado. Por favor, otorga el permiso para continuar.';
}

class LocationPermissionPermanentlyDeniedException implements Exception {
  const LocationPermissionPermanentlyDeniedException();

  @override
  String toString() =>
      'Permiso de ubicación denegado permanentemente. Ve a Configuración > Aplicaciones para habilitarlo.';
}

// ════════════════════════════════════════════════════════════════════════════
// IMPLEMENTACIÓN
// ════════════════════════════════════════════════════════════════════════════

class ExploreRepositoryImpl implements ExploreRepository {
  ExploreRepositoryImpl({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  // ── Constantes ─────────────────────────────────────────────────────────────

  static const _kBarbershopsCol = 'barbershops';
  static const _kServicesCol = 'services_explore';
  static const _kUsersCol = 'users';
  static const _kFavoritesCol = 'favorites';

  // Radio por defecto: 10 km — cubre Ciudad Neily y alrededores.
  static const _kDefaultRadiusKm = 10.0;

  // ── Barberías cercanas ────────────────────────────────────────────────────

  @override
  Stream<List<BarbershopEntity>> getNearbyBarbershops({
    required double lat,
    required double lng,
    double radiusKm = _kDefaultRadiusKm,
  }) {
    final geoRef = GeoCollectionReference<Map<String, dynamic>>(
      _db.collection(_kBarbershopsCol),
    );

    return geoRef
        .subscribeWithin(
          center: GeoFirePoint(GeoPoint(lat, lng)),
          radiusInKm: radiusKm,
          field: 'position',
          geopointFrom: (data) => (data['position']['geopoint'] as GeoPoint),
          queryBuilder: (query) => query.where('isActive', isEqualTo: true),
        )
        .map(
          (docs) => docs
              .map((doc) => BarbershopModel.fromDocument(doc).toEntity())
              .toList(),
        );
  }

  // ── Servicios cercanos ────────────────────────────────────────────────────

  @override
  Stream<List<ServiceExploreEntity>> getNearbyServices({
    required double lat,
    required double lng,
    double radiusKm = _kDefaultRadiusKm,
    String? category,
  }) {
    final geoRef = GeoCollectionReference<Map<String, dynamic>>(
      _db.collection(_kServicesCol),
    );

    return geoRef
        .subscribeWithin(
          center: GeoFirePoint(GeoPoint(lat, lng)),
          radiusInKm: radiusKm,
          field: 'position',
          geopointFrom: (data) => (data['position']['geopoint'] as GeoPoint),
          queryBuilder: (query) {
            var q = query.where('isActive', isEqualTo: true);
            if (category != null) {
              // Requiere índice compuesto: [position.geohash, category, isActive]
              q = q.where('category', isEqualTo: category);
            }
            return q;
          },
        )
        .map(
          (docs) => docs
              .map((doc) => ServiceExploreModel.fromDocument(doc).toEntity())
              .toList(),
        );
  }

  // ── Favoritos ─────────────────────────────────────────────────────────────

  @override
  Stream<List<String>> getUserFavoriteIds(String userId) {
    // La subcolección vacía emite un snapshot con 0 documentos → retorna [].
    // El BLoC detecta la lista vacía y emite ExploreFavoritesEmpty.
    return _db
        .collection(_kUsersCol)
        .doc(userId)
        .collection(_kFavoritesCol)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }

  @override
  Future<void> toggleFavorite({
    required String userId,
    required String barbershopId,
    required bool isCurrentlyFavorite,
  }) async {
    final ref = _db
        .collection(_kUsersCol)
        .doc(userId)
        .collection(_kFavoritesCol)
        .doc(barbershopId);

    if (isCurrentlyFavorite) {
      await ref.delete();
    } else {
      await ref.set({
        'barbershopId': barbershopId,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ── Geolocalización ───────────────────────────────────────────────────────

  @override
  Future<Position> getCurrentPosition() async {
    // 1. Verificar si el servicio de ubicación está habilitado en el dispositivo
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    // 2. Verificar permisos actuales
    LocationPermission permission = await Geolocator.checkPermission();

    // 3. Si está denegado pero no permanentemente, solicitarlo
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationPermissionDeniedException();
      }
    }

    // 4. Si está denegado permanentemente, redirigir a configuración del sistema
    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionPermanentlyDeniedException();
    }

    // 5. Obtener posición con precisión alta; timeout 15 s
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }
}
