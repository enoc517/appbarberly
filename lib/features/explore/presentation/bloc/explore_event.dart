// lib/features/explore/presentation/bloc/explore_event.dart
//
// Eventos del BLoC de Explorar.
// Archivo separado siguiendo el patrón estándar de flutter_bloc:
//   explore_event.dart  ← este archivo
//   explore_state.dart
//   explore_bloc.dart
// ===========================================================================

part of 'explore_bloc.dart';

// ════════════════════════════════════════════════════════════════════════════
// CLASE BASE
// ════════════════════════════════════════════════════════════════════════════

abstract class ExploreEvent extends Equatable {
  const ExploreEvent();

  @override
  List<Object?> get props => [];
}

// ════════════════════════════════════════════════════════════════════════════
// EVENTOS PÚBLICOS — disparados desde la UI o la capa de presentación
// ════════════════════════════════════════════════════════════════════════════

/// Inicializa la vista: solicita permiso, obtiene posición y lanza los streams.
class ExploreInitialized extends ExploreEvent {
  const ExploreInitialized({this.userId});

  final String? userId;

  @override
  List<Object?> get props => [userId];
}

/// El usuario escribió en la barra de búsqueda.
class ExploreSearchQueryChanged extends ExploreEvent {
  const ExploreSearchQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// El usuario seleccionó una barbería en la lista/buscador.
/// El BLoC mueve la cámara del mapa a esa posición.
class ExploreMapBarbershopSelected extends ExploreEvent {
  const ExploreMapBarbershopSelected(this.barbershop);

  final BarbershopEntity barbershop;

  @override
  List<Object?> get props => [barbershop];
}

/// El usuario cambió el criterio de ordenamiento.
class ExploreSortChanged extends ExploreEvent {
  const ExploreSortChanged(this.sort);

  final ExploreSort sort;

  @override
  List<Object?> get props => [sort];
}

/// El usuario cambió el filtro de categoría de servicios.
class ExploreCategoryFilterChanged extends ExploreEvent {
  const ExploreCategoryFilterChanged(this.category);

  /// null = todas las categorías.
  final String? category;

  @override
  List<Object?> get props => [category];
}

/// El usuario tocó el botón de favorito en una card.
class ExploreToggleFavorite extends ExploreEvent {
  const ExploreToggleFavorite({
    required this.userId,
    required this.barbershopId,
    required this.isCurrentlyFavorite,
  });

  final String userId;
  final String barbershopId;
  final bool isCurrentlyFavorite;

  @override
  List<Object?> get props => [userId, barbershopId, isCurrentlyFavorite];
}

/// El controlador del mapa fue entregado por la vista.
class ExploreMapControllerReady extends ExploreEvent {
  const ExploreMapControllerReady(this.controller);

  final MapController controller;

  @override
  List<Object?> get props => [controller];
}

// ════════════════════════════════════════════════════════════════════════════
// EVENTOS INTERNOS — solo el BLoC los dispara; prefijo _ para privacidad
// ════════════════════════════════════════════════════════════════════════════

/// El stream de Firestore emitió nuevas barberías cercanas.
class _BarbershopsUpdated extends ExploreEvent {
  const _BarbershopsUpdated(this.barbershops);

  final List<BarbershopEntity> barbershops;

  @override
  List<Object?> get props => [barbershops];
}

/// El stream de Firestore emitió nuevos servicios cercanos.
class _ServicesUpdated extends ExploreEvent {
  const _ServicesUpdated(this.services);

  final List<ServiceExploreEntity> services;

  @override
  List<Object?> get props => [services];
}

/// El stream de favoritos emitió una actualización.
class _FavoritesUpdated extends ExploreEvent {
  const _FavoritesUpdated(this.favoriteIds);

  final List<String> favoriteIds;

  @override
  List<Object?> get props => [favoriteIds];
}

/// El usuario cambió el radio de búsqueda en kilómetros.
class ExploreRadiusChanged extends ExploreEvent {
  const ExploreRadiusChanged(this.radiusKm);

  final double radiusKm;

  @override
  List<Object?> get props => [radiusKm];
}
