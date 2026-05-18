// lib/features/explore/presentation/bloc/explore_state.dart
//
// Estados del BLoC de Explorar.
// Archivo separado siguiendo el patrón estándar de flutter_bloc:
//   explore_event.dart
//   explore_state.dart  ← este archivo
//   explore_bloc.dart
// ===========================================================================

part of 'explore_bloc.dart';

// ════════════════════════════════════════════════════════════════════════════
// CLASE BASE
// ════════════════════════════════════════════════════════════════════════════

abstract class ExploreState extends Equatable {
  const ExploreState();

  @override
  List<Object?> get props => [];
}

// ════════════════════════════════════════════════════════════════════════════
// ESTADOS CONCRETOS
// ════════════════════════════════════════════════════════════════════════════

/// Carga inicial — el mapa aún no tiene datos.
class ExploreInitial extends ExploreState {
  const ExploreInitial();
}

/// Obteniendo posición del GPS / suscribiendo streams de Firestore.
class ExploreLoading extends ExploreState {
  const ExploreLoading();
}

/// Datos disponibles y mapa listo para mostrar.
class ExploreLoaded extends ExploreState {
  const ExploreLoaded({
    required this.barbershops,
    required this.services,
    required this.markers,
    required this.favoriteIds,
    required this.currentSort,
    required this.userLat,
    required this.userLng,
    required this.userName,
    this.searchQuery = '',
    this.categoryFilter,
    this.cameraTarget,
  });

  /// Lista filtrada y ordenada de barberías (post-búsqueda y post-sort).
  final List<BarbershopEntity> barbershops;

  /// Lista filtrada de servicios (post-categoría).
  final List<ServiceExploreEntity> services;

  /// Set de marcadores ya construidos — pasarlo directamente a FlutterMap.
  final List<Marker> markers;

  /// IDs de favoritos del usuario actual.
  final List<String> favoriteIds;

  final ExploreSort currentSort;
  final double userLat;
  final double userLng;
  final String userName;
  final String searchQuery;

  /// null = todas las categorías; string = filtro activo.
  final String? categoryFilter;

  /// Cuando != null, la vista anima la cámara a esta posición y lo resetea.
  final LatLng? cameraTarget;

  // ── Helper ────────────────────────────────────────────────────────────────

  /// Retorna true si esta barbería está en la lista de favoritos del usuario.
  bool isFavorite(String barbershopId) => favoriteIds.contains(barbershopId);

  // ── copyWith ──────────────────────────────────────────────────────────────
  //
  // categoryFilter y cameraTarget son nullable-por-diseño, por lo que usan
  // el patrón de función anónima `T? Function()?` para distinguir entre
  // "no actualizar este campo" y "actualizarlo a null explícitamente".

  ExploreLoaded copyWith({
    List<BarbershopEntity>? barbershops,
    List<ServiceExploreEntity>? services,
    List<Marker>? markers,
    List<String>? favoriteIds,
    ExploreSort? currentSort,
    double? userLat,
    double? userLng,
    String? userName,
    String? searchQuery,
    String? Function()? categoryFilter,
    LatLng? Function()? cameraTarget,
  }) {
    return ExploreLoaded(
      barbershops: barbershops ?? this.barbershops,
      services: services ?? this.services,
      markers: markers ?? this.markers,
      favoriteIds: favoriteIds ?? this.favoriteIds,
      currentSort: currentSort ?? this.currentSort,
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
      userName: userName ?? this.userName,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter != null
          ? categoryFilter()
          : this.categoryFilter,
      cameraTarget: cameraTarget != null ? cameraTarget() : this.cameraTarget,
    );
  }

  @override
  List<Object?> get props => [
    barbershops,
    services,
    markers,
    favoriteIds,
    currentSort,
    userLat,
    userLng,
    userName,
    searchQuery,
    categoryFilter,
    cameraTarget,
  ];
}

/// Estado legado. La pantalla principal debe mantenerse en [ExploreLoaded]
/// aunque el usuario no tenga favoritos.
class ExploreFavoritesEmpty extends ExploreState {
  const ExploreFavoritesEmpty();
}

/// Error de permisos, conexión u otro fallo no recuperable.
class ExploreError extends ExploreState {
  const ExploreError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
