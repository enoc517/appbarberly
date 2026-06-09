// lib/features/explore/presentation/bloc/explore_bloc.dart
//
// BLoC principal de la feature de Explorar.
//
// Este archivo solo contiene la lógica de los handlers on<Event>.
// Los eventos y estados se declaran en sus archivos propios mediante `part`:
//   explore_event.dart  — abstract ExploreEvent + todos los eventos
//   explore_state.dart  — abstract ExploreState + todos los estados
//
// Responsabilidades:
//   · Obtener posición del usuario (con fallback a Ciudad Neily)
//   · Suscribirse a streams geo de barberías y servicios
//   · Detectar favoritos vacíos y emitir estado dedicado
//   · Construir marcadores (via MarkerUtils) con pin ⚡ para promos
//   · Sincronizar la cámara del mapa cuando el usuario selecciona
//     una barbería en el buscador
//   · Gestionar filtros de categoría y ordenamiento en cliente
//
// Principio aplicado: Inversión de Dependencias (SOLID — D)
//   · ExploreBloc depende de ExploreRepository (interfaz de dominio).
//   · La implementación concreta (ExploreRepositoryImpl) se inyecta
//     desde el árbol de widgets — el BLoC nunca la instancia directamente.
// ===========================================================================

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:barberly/features/explore/domain/entities/explore_entities.dart';
import 'package:barberly/features/explore/domain/repositories/explore_repository.dart';
import 'package:barberly/features/explore/data/repositories/explore_repository_impl.dart'
    show
        LocationPermissionDeniedException,
        LocationPermissionPermanentlyDeniedException;
import 'package:barberly/features/explore/presentation/utils/marker_utils.dart';
import 'package:barberly/features/auth/domain/usecases/get_current_user.dart';

part 'explore_event.dart';
part 'explore_state.dart';

// ════════════════════════════════════════════════════════════════════════════
// BLOC
// ════════════════════════════════════════════════════════════════════════════

class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  ExploreBloc({
    required ExploreRepository repository,
    required GetCurrentUserUseCase getCurrentUserUseCase,
  }) : _repo = repository,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       super(const ExploreInitial()) {
    on<ExploreInitialized>(_onInitialized);
    on<_BarbershopsUpdated>(_onBarbershopsUpdated);
    on<_ServicesUpdated>(_onServicesUpdated);
    on<_FavoritesUpdated>(_onFavoritesUpdated);
    on<ExploreSearchQueryChanged>(_onSearchQueryChanged);
    on<ExploreMapBarbershopSelected>(_onBarbershopSelected);
    on<ExploreSortChanged>(_onSortChanged);
    on<ExploreCategoryFilterChanged>(_onCategoryFilterChanged);
    on<ExploreRadiusChanged>(_onRadiusChanged);
    on<ExploreToggleFavorite>(_onToggleFavorite);
    on<ExploreMapControllerReady>(_onMapControllerReady);
  }

  final ExploreRepository _repo;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  // Coordenadas de Ciudad Neily — fallback si GPS no disponible
  static const _kNeilyLat = 8.6131;
  static const _kNeilyLng = -82.9589;

  // Suscripciones activas a Firestore streams
  StreamSubscription<List<BarbershopEntity>>? _barbershopsSubscription;
  StreamSubscription<List<ServiceExploreEntity>>? _servicesSubscription;
  StreamSubscription<List<String>>? _favoritesSubscription;

  // Estado interno mutable (no en el estado público para evitar rebuilds)
  List<BarbershopEntity> _allBarbershops = [];
  List<ServiceExploreEntity> _allServices = [];
  List<String> _favoriteIds = [];
  MapController? _mapController;
  double _userLat = _kNeilyLat;
  double _userLng = _kNeilyLng;
  double _radiusKm = 10.0;

  // ── ExploreInitialized ────────────────────────────────────────────────────

  Future<void> _onInitialized(
    ExploreInitialized event,
    Emitter<ExploreState> emit,
  ) async {
    emit(const ExploreLoading());

    double lat = _kNeilyLat;
    double lng = _kNeilyLng;
    String userName = 'Usuario';
    String? userId = event.userId;

    try {
      final user = await _getCurrentUserUseCase();
      userId ??= user?.id;
      userName = _displayNameFor(user?.fullName, user?.email);
    } catch (_) {
      userName = 'Usuario';
    }

    // Intentar obtener GPS real; si falla, usar Ciudad Neily
    try {
      final pos = await _repo.getCurrentPosition();
      lat = pos.latitude;
      lng = pos.longitude;
      _userLat = lat;
      _userLng = lng;
    } on LocationPermissionDeniedException catch (e) {
      emit(ExploreError(e.toString()));
      return;
    } on LocationPermissionPermanentlyDeniedException catch (e) {
      emit(ExploreError(e.toString()));
      return;
    } catch (e) {
      _userLat = lat;
      _userLng = lng;
    }

    // ── Suscribir streams de Firestore ────────────────────────────────────
    await _subscribeNearbyStreams(lat: lat, lng: lng, radiusKm: _radiusKm);

    if (userId != null) {
      _favoritesSubscription = _repo.getUserFavoriteIds(userId).listen((ids) {
        add(_FavoritesUpdated(ids));
      }, onError: (_) => add(const _FavoritesUpdated([])));
    } else {
    }

    // Emitir estado inicial vacío con la posición del usuario
    final initialMarkers = MarkerUtils.buildMarkers(
      barbershops: const [],
      onTap: (shop) => add(ExploreMapBarbershopSelected(shop)),
    );

    emit(
      ExploreLoaded(
        barbershops: const [],
        services: const [],
        markers: initialMarkers,
        favoriteIds: const [],
        currentSort: ExploreSort.cercania,
        userLat: lat,
        userLng: lng,
        userName: userName,
        radiusKm: _radiusKm,
      ),
    );
  }

  // ── _BarbershopsUpdated ───────────────────────────────────────────────────

  Future<void> _onBarbershopsUpdated(
    _BarbershopsUpdated event,
    Emitter<ExploreState> emit,
  ) async {
    _allBarbershops = event.barbershops;
    await _rebuildAndEmit(emit);
  }

  // ── _ServicesUpdated ──────────────────────────────────────────────────────

  Future<void> _onServicesUpdated(
    _ServicesUpdated event,
    Emitter<ExploreState> emit,
  ) async {
    _allServices = event.services;
    await _rebuildAndEmit(emit);
  }

  // ── _FavoritesUpdated ─────────────────────────────────────────────────────

  Future<void> _onFavoritesUpdated(
    _FavoritesUpdated event,
    Emitter<ExploreState> emit,
  ) async {
    _favoriteIds = event.favoriteIds;

    await _rebuildAndEmit(emit);
  }

  // ── ExploreSearchQueryChanged ─────────────────────────────────────────────

  Future<void> _onSearchQueryChanged(
    ExploreSearchQueryChanged event,
    Emitter<ExploreState> emit,
  ) async {
    if (state is! ExploreLoaded) return;
    final current = state as ExploreLoaded;

    final filtered = _applyFilters(
      barbershops: _allBarbershops,
      services: _allServices,
      query: event.query,
      sort: current.currentSort,
    );

    final filteredServices = _applyServiceFilters(
      services: _allServices,
      query: event.query,
      category: current.categoryFilter,
    );

    final markers = MarkerUtils.buildMarkers(
      barbershops: filtered,
      onTap: (shop) => add(ExploreMapBarbershopSelected(shop)),
    );

    emit(
      current.copyWith(
        barbershops: filtered,
        services: filteredServices,
        markers: markers,
        searchQuery: event.query,
      ),
    );
  }

  // ── ExploreMapBarbershopSelected ──────────────────────────────────────────
  //
  // Cuando el usuario toca una barbería en la lista, el BLoC:
  //   1. Emite cameraTarget para que la vista anime el mapa.
  //   2. Resetea cameraTarget a null para no re-animar en rebuilds futuros.

  Future<void> _onBarbershopSelected(
    ExploreMapBarbershopSelected event,
    Emitter<ExploreState> emit,
  ) async {
    if (state is! ExploreLoaded) return;
    final current = state as ExploreLoaded;
    final target = LatLng(event.barbershop.lat, event.barbershop.lng);

    if (_mapController != null) {
      _mapController!.move(target, 15.5);
    }

    // También propaga el target en el estado para que la vista pueda reaccionar
    // (útil si el controlador aún no estaba listo)
    emit(current.copyWith(cameraTarget: () => target));

    // Limpiar el target en el siguiente ciclo para evitar re-animaciones
    await Future.microtask(() {
      if (state is ExploreLoaded) {
        emit((state as ExploreLoaded).copyWith(cameraTarget: () => null));
      }
    });
  }

  // ── ExploreSortChanged ────────────────────────────────────────────────────

  Future<void> _onSortChanged(
    ExploreSortChanged event,
    Emitter<ExploreState> emit,
  ) async {
    if (state is! ExploreLoaded) return;
    final current = state as ExploreLoaded;

    final sorted = _applySortOnly(
      barbershops: current.barbershops,
      sort: event.sort,
    );

    final markers = MarkerUtils.buildMarkers(
      barbershops: sorted,
      onTap: (shop) => add(ExploreMapBarbershopSelected(shop)),
    );

    emit(
      current.copyWith(
        barbershops: sorted,
        markers: markers,
        currentSort: event.sort,
      ),
    );
  }

  // ── ExploreCategoryFilterChanged ──────────────────────────────────────────

  Future<void> _onCategoryFilterChanged(
    ExploreCategoryFilterChanged event,
    Emitter<ExploreState> emit,
  ) async {
    if (state is! ExploreLoaded) return;
    final current = state as ExploreLoaded;

    final filtered = _applyServiceFilters(
      services: _allServices,
      query: current.searchQuery,
      category: event.category,
    );

    emit(
      current.copyWith(
        services: filtered,
        categoryFilter: () => event.category,
      ),
    );
  }

  Future<void> _onRadiusChanged(
    ExploreRadiusChanged event,
    Emitter<ExploreState> emit,
  ) async {
    if (state is! ExploreLoaded) return;
    final current = state as ExploreLoaded;
    _radiusKm = event.radiusKm;

    emit(current.copyWith(radiusKm: event.radiusKm));
    await _subscribeNearbyStreams(
      lat: _userLat,
      lng: _userLng,
      radiusKm: event.radiusKm,
    );
  }

  // ── ExploreToggleFavorite ─────────────────────────────────────────────────

  Future<void> _onToggleFavorite(
    ExploreToggleFavorite event,
    Emitter<ExploreState> emit,
  ) async {
    try {
      await _repo.toggleFavorite(
        userId: event.userId,
        barbershopId: event.barbershopId,
        isCurrentlyFavorite: event.isCurrentlyFavorite,
      );
      // El stream de favoritos emitirá la actualización automáticamente
    } catch (e) {
      emit(ExploreError('No se pudo actualizar el favorito: ${e.toString()}'));
    }
  }

  // ── ExploreMapControllerReady ─────────────────────────────────────────────

  Future<void> _onMapControllerReady(
    ExploreMapControllerReady event,
    Emitter<ExploreState> emit,
  ) async {
    _mapController = event.controller;

    // Si ya hay un cameraTarget pendiente en el estado, mover la cámara ahora
    if (state is ExploreLoaded) {
      final target = (state as ExploreLoaded).cameraTarget;
      if (target != null) {
        _mapController!.move(target, 15.5);
      }
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // HELPERS PRIVADOS
  // ════════════════════════════════════════════════════════════════════════

  /// Reconstruye marcadores y emite un nuevo ExploreLoaded coherente.
  Future<void> _rebuildAndEmit(Emitter<ExploreState> emit) async {
    if (state is! ExploreLoaded) return;
    final current = state as ExploreLoaded;

    final filtered = _applyFilters(
      barbershops: _allBarbershops,
      services: _allServices,
      query: current.searchQuery,
      sort: current.currentSort,
    );

    final filteredServices = _applyServiceFilters(
      services: _allServices,
      query: current.searchQuery,
      category: current.categoryFilter,
    );

    final markers = MarkerUtils.buildMarkers(
      barbershops: filtered,
      onTap: (shop) => add(ExploreMapBarbershopSelected(shop)),
    );

    emit(
      current.copyWith(
        barbershops: filtered,
        services: filteredServices,
        markers: markers,
        favoriteIds: _favoriteIds,
      ),
    );
  }

  /// Aplica búsqueda por texto Y ordenamiento.
  List<BarbershopEntity> _applyFilters({
    required List<BarbershopEntity> barbershops,
    required List<ServiceExploreEntity> services,
    required String query,
    required ExploreSort sort,
  }) {
    return applyExploreSearch(
      barbershops: barbershops,
      services: services,
      query: query,
      sort: sort,
    );
  }

  List<ServiceExploreEntity> _applyServiceFilters({
    required List<ServiceExploreEntity> services,
    required String query,
    required String? category,
  }) {
    final normalizedQuery = normalizeExploreQuery(query);
    return services.where((service) {
      final matchesCategory = category == null || service.category == category;
      if (!matchesCategory) return false;
      if (normalizedQuery.isEmpty) return true;

      return normalizeExploreQuery(
            service.serviceName,
          ).contains(normalizedQuery) ||
          normalizeExploreQuery(
            service.barbershopSnapshot.name,
          ).contains(normalizedQuery) ||
          normalizeExploreQuery(service.description).contains(normalizedQuery);
    }).toList();
  }

  /// Solo aplica ordenamiento sobre la lista recibida.
  List<BarbershopEntity> _applySortOnly({
    required List<BarbershopEntity> barbershops,
    required ExploreSort sort,
  }) {
    return _sortExploreBarbershops(barbershops, sort);
  }

  String _displayNameFor(String? fullName, String? email) {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name.split(' ').first;

    final mail = email?.trim();
    if (mail != null && mail.isNotEmpty) return mail.split('@').first;

    return 'Usuario';
  }

  Future<void> _subscribeNearbyStreams({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    await _barbershopsSubscription?.cancel();
    await _servicesSubscription?.cancel();

    _barbershopsSubscription = _repo
        .getNearbyBarbershops(lat: lat, lng: lng, radiusKm: radiusKm)
        .listen(
          (shops) {
            add(_BarbershopsUpdated(_withDistances(shops, lat, lng)));
          },
          onError: (_) {
            add(const _BarbershopsUpdated([]));
          },
        );

    _servicesSubscription = _repo
        .getNearbyServices(lat: lat, lng: lng, radiusKm: radiusKm)
        .listen(
          (svcs) {
            add(_ServicesUpdated(_servicesWithDistances(svcs, lat, lng)));
          },
          onError: (_) {
            add(const _ServicesUpdated([]));
          },
        );
  }

  List<BarbershopEntity> _withDistances(
    List<BarbershopEntity> shops,
    double lat,
    double lng,
  ) {
    return applyBarbershopDistances(shops: shops, userLat: lat, userLng: lng);
  }

  List<ServiceExploreEntity> _servicesWithDistances(
    List<ServiceExploreEntity> services,
    double lat,
    double lng,
  ) {
    const distance = Distance();
    final userLocation = LatLng(lat, lng);
    return services.map((service) {
      final meters = distance(userLocation, LatLng(service.lat, service.lng));
      return ServiceExploreEntity(
        id: service.id,
        barbershopId: service.barbershopId,
        barbershopSnapshot: service.barbershopSnapshot,
        serviceName: service.serviceName,
        description: service.description,
        price: service.price,
        durationMinutes: service.durationMinutes,
        category: service.category,
        lat: service.lat,
        lng: service.lng,
        distanceKm: meters / 1000,
      );
    }).toList();
  }

  /// Cancela todas las suscripciones activas.
  Future<void> _cancelSubscriptions() async {
    await _barbershopsSubscription?.cancel();
    await _servicesSubscription?.cancel();
    await _favoritesSubscription?.cancel();
    _barbershopsSubscription = null;
    _servicesSubscription = null;
    _favoritesSubscription = null;
  }

  @override
  Future<void> close() async {
    await _cancelSubscriptions();
    _mapController?.dispose();
    return super.close();
  }
}

@visibleForTesting
List<BarbershopEntity> applyBarbershopDistances({
  required List<BarbershopEntity> shops,
  required double userLat,
  required double userLng,
}) {
  const distance = Distance();
  final userLocation = LatLng(userLat, userLng);
  return shops.map((shop) {
    final meters = distance(userLocation, LatLng(shop.lat, shop.lng));
    return shop.copyWith(distanceKm: meters / 1000);
  }).toList();
}

@visibleForTesting
String normalizeExploreQuery(String value) {
  const replacements = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };

  var result = value.toLowerCase().trim();
  for (final entry in replacements.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }
  return result;
}

@visibleForTesting
List<BarbershopEntity> applyExploreSearch({
  required List<BarbershopEntity> barbershops,
  required List<ServiceExploreEntity> services,
  required String query,
  required ExploreSort sort,
}) {
  var result = barbershops;
  final normalizedQuery = normalizeExploreQuery(query);

  if (normalizedQuery.isNotEmpty) {
    final matchingServiceShopIds = services
        .where(
          (service) =>
              normalizeExploreQuery(
                service.serviceName,
              ).contains(normalizedQuery) ||
              normalizeExploreQuery(
                service.description,
              ).contains(normalizedQuery) ||
              normalizeExploreQuery(
                service.barbershopSnapshot.name,
              ).contains(normalizedQuery),
        )
        .map((service) => service.barbershopId)
        .toSet();

    result = result.where((shop) {
      return normalizeExploreQuery(shop.name).contains(normalizedQuery) ||
          normalizeExploreQuery(shop.ownerName).contains(normalizedQuery) ||
          normalizeExploreQuery(shop.address).contains(normalizedQuery) ||
          shop.tags.any(
            (tag) => normalizeExploreQuery(tag).contains(normalizedQuery),
          ) ||
          shop.barberNames.any(
            (name) => normalizeExploreQuery(name).contains(normalizedQuery),
          ) ||
          matchingServiceShopIds.contains(shop.id);
    }).toList();
  }

  return _sortExploreBarbershops(result, sort);
}

List<BarbershopEntity> _sortExploreBarbershops(
  List<BarbershopEntity> barbershops,
  ExploreSort sort,
) {
  switch (sort) {
    case ExploreSort.cercania:
      return [...barbershops]
        ..sort((a, b) => (a.distanceKm ?? 0).compareTo(b.distanceKm ?? 0));
    case ExploreSort.calificacion:
      return [...barbershops]..sort((a, b) => b.rating.compareTo(a.rating));
    case ExploreSort.conOferta:
      return [...barbershops]..sort((a, b) {
        final promoA = a.hasActivePromotion ? 0 : 1;
        final promoB = b.hasActivePromotion ? 0 : 1;
        if (promoA != promoB) return promoA.compareTo(promoB);
        return b.rating.compareTo(a.rating);
      });
  }
}
