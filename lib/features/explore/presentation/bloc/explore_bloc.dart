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

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:barberly/features/explore/domain/entities/explore_entities.dart';
import 'package:barberly/features/explore/domain/repositories/explore_repository.dart';
import 'package:barberly/features/explore/data/repositories/explore_repository_impl.dart'
    show
        LocationPermissionDeniedException,
        LocationPermissionPermanentlyDeniedException;
import 'package:barberly/features/explore/presentation/utils/marker_utils.dart';

part 'explore_event.dart';
part 'explore_state.dart';

// ════════════════════════════════════════════════════════════════════════════
// BLOC
// ════════════════════════════════════════════════════════════════════════════

class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  ExploreBloc({required ExploreRepository repository})
    : _repo = repository,
      super(const ExploreInitial()) {
    on<ExploreInitialized>(_onInitialized);
    on<_BarbershopsUpdated>(_onBarbershopsUpdated);
    on<_ServicesUpdated>(_onServicesUpdated);
    on<_FavoritesUpdated>(_onFavoritesUpdated);
    on<ExploreSearchQueryChanged>(_onSearchQueryChanged);
    on<ExploreMapBarbershopSelected>(_onBarbershopSelected);
    on<ExploreSortChanged>(_onSortChanged);
    on<ExploreCategoryFilterChanged>(_onCategoryFilterChanged);
    on<ExploreToggleFavorite>(_onToggleFavorite);
    on<ExploreMapControllerReady>(_onMapControllerReady);
  }

  final ExploreRepository _repo;

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
  GoogleMapController? _mapController;

  // ── ExploreInitialized ────────────────────────────────────────────────────

  Future<void> _onInitialized(
    ExploreInitialized event,
    Emitter<ExploreState> emit,
  ) async {
    print('🔵 [ExploreBloc] _onInitialized START');
    emit(const ExploreLoading());

    double lat = _kNeilyLat;
    double lng = _kNeilyLng;

    // Intentar obtener GPS real; si falla, usar Ciudad Neily
    try {
      print('🔵 [ExploreBloc] Solicitando GPS...');
      final pos = await _repo.getCurrentPosition();
      lat = pos.latitude;
      lng = pos.longitude;
      print('🟢 [ExploreBloc] GPS OK: $lat, $lng');
    } on LocationPermissionDeniedException catch (e) {
      print('🔴 [ExploreBloc] PERMISO DENEGADO: $e');
      emit(ExploreError(e.toString()));
      return;
    } on LocationPermissionPermanentlyDeniedException catch (e) {
      print('🔴 [ExploreBloc] PERMISO DENEGADO PERMANENTEMENTE: $e');
      emit(ExploreError(e.toString()));
      return;
    } catch (e) {
      print('🟡 [ExploreBloc] GPS falló, usando fallback Neily: $e');
    }

    // ── Suscribir streams de Firestore ────────────────────────────────────
    print('🔵 [ExploreBloc] Suscribiendo streams en ($lat, $lng)...');
    await _cancelSubscriptions();

    _barbershopsSubscription = _repo
        .getNearbyBarbershops(lat: lat, lng: lng)
        .listen(
          (shops) {
            print(
              '🟢 [ExploreBloc] Stream barberías: ${shops.length} resultados',
            );
            for (final s in shops) {
              print('   · ${s.name} (${s.lat}, ${s.lng})');
            }
            add(_BarbershopsUpdated(shops));
          },
          onError: (e) {
            print('🔴 [ExploreBloc] Stream barberías ERROR: $e');
            add(const _BarbershopsUpdated([]));
          },
        );

    _servicesSubscription = _repo
        .getNearbyServices(lat: lat, lng: lng)
        .listen(
          (svcs) {
            print(
              '🟢 [ExploreBloc] Stream servicios: ${svcs.length} resultados',
            );
            add(_ServicesUpdated(svcs));
          },
          onError: (e) {
            print('🔴 [ExploreBloc] Stream servicios ERROR: $e');
            add(const _ServicesUpdated([]));
          },
        );

    if (event.userId != null) {
      print('🔵 [ExploreBloc] Suscribiendo favoritos para ${event.userId}');
      _favoritesSubscription = _repo.getUserFavoriteIds(event.userId!).listen((
        ids,
      ) {
        print('🟢 [ExploreBloc] Stream favoritos: ${ids.length} IDs');
        add(_FavoritesUpdated(ids));
      }, onError: (_) => add(const _FavoritesUpdated([])));
    } else {
      print('🟡 [ExploreBloc] Sin userId — no se suscribe a favoritos');
    }

    // Emitir estado inicial vacío con la posición del usuario
    final initialMarkers = await MarkerUtils.buildMarkers(
      barbershops: const [],
      onTap: (shop) => add(ExploreMapBarbershopSelected(shop)),
    );

    print('🟢 [ExploreBloc] Emitiendo ExploreLoaded inicial vacío');
    emit(
      ExploreLoaded(
        barbershops: const [],
        services: const [],
        markers: initialMarkers,
        favoriteIds: const [],
        currentSort: ExploreSort.cercania,
        userLat: lat,
        userLng: lng,
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
    print(
      '🔵 [ExploreBloc] _onFavoritesUpdated: ${event.favoriteIds.length} IDs',
    );
    _favoriteIds = event.favoriteIds;

    // Si el usuario no tiene favoritos, emitir estado dedicado para el mensaje
    if (_favoriteIds.isEmpty) {
      print(
        '🟡 [ExploreBloc] Favoritos vacíos — emitiendo ExploreFavoritesEmpty',
      );
      print('🟡 [ExploreBloc] ⚠️ ESTO PUEDE PISAR ExploreLoaded ⚠️');
      emit(const ExploreFavoritesEmpty());
      return;
    }

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
      query: event.query,
      sort: current.currentSort,
    );

    final markers = await MarkerUtils.buildMarkers(
      barbershops: filtered,
      onTap: (shop) => add(ExploreMapBarbershopSelected(shop)),
    );

    emit(
      current.copyWith(
        barbershops: filtered,
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

    // Mover la cámara directamente si el controlador ya está disponible
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 15.5),
        ),
      );
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
      barbershops: _allBarbershops,
      sort: event.sort,
    );

    final markers = await MarkerUtils.buildMarkers(
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

    final filtered = event.category == null
        ? _allServices
        : _allServices.where((s) => s.category == event.category).toList();

    emit(
      current.copyWith(
        services: filtered,
        categoryFilter: () => event.category,
      ),
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
        await _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: target, zoom: 15.5),
          ),
        );
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
      query: current.searchQuery,
      sort: current.currentSort,
    );

    final filteredServices = current.categoryFilter == null
        ? _allServices
        : _allServices
              .where((s) => s.category == current.categoryFilter)
              .toList();

    final markers = await MarkerUtils.buildMarkers(
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
    required String query,
    required ExploreSort sort,
  }) {
    var result = barbershops;

    // Filtro de búsqueda (nombre o dirección, insensible a mayúsculas)
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result
          .where(
            (s) =>
                s.name.toLowerCase().contains(q) ||
                s.address.toLowerCase().contains(q) ||
                s.tags.any((tag) => tag.toLowerCase().contains(q)),
          )
          .toList();
    }

    return _applySortOnly(barbershops: result, sort: sort);
  }

  /// Solo aplica ordenamiento sobre la lista recibida.
  List<BarbershopEntity> _applySortOnly({
    required List<BarbershopEntity> barbershops,
    required ExploreSort sort,
  }) {
    switch (sort) {
      case ExploreSort.cercania:
        // geoflutterfire_plus ya entrega el stream ordenado por distancia ✓
        return barbershops;

      case ExploreSort.calificacion:
        return [...barbershops]..sort((a, b) => b.rating.compareTo(a.rating));

      case ExploreSort.conOferta:
        return [...barbershops]..sort((a, b) {
          // Primero los que tienen promo activa
          final promoA = a.hasActivePromotion ? 0 : 1;
          final promoB = b.hasActivePromotion ? 0 : 1;
          if (promoA != promoB) return promoA.compareTo(promoB);
          // Desempate por rating
          return b.rating.compareTo(a.rating);
        });
    }
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
