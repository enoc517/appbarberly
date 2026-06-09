import 'package:barberly/features/explore/domain/entities/explore_entities.dart';
import 'package:barberly/features/explore/presentation/bloc/explore_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('applyExploreSearch', () {
    test('matches barbershops by barbershop name', () {
      final result = applyExploreSearch(
        barbershops: [_imperio(), _navaja()],
        services: const [],
        query: 'imperio',
        sort: ExploreSort.cercania,
      );

      expect(result.map((shop) => shop.id), ['imperio']);
    });

    test('matches barbershops by barber name ignoring accents', () {
      final result = applyExploreSearch(
        barbershops: [_imperio(), _navaja()],
        services: const [],
        query: 'oscar',
        sort: ExploreSort.cercania,
      );

      expect(result.map((shop) => shop.id), ['navaja']);
    });

    test('matches barbershops by denormalized service name', () {
      final result = applyExploreSearch(
        barbershops: [_imperio(), _navaja()],
        services: [_beardService()],
        query: 'barba',
        sort: ExploreSort.cercania,
      );

      expect(result.map((shop) => shop.id), ['imperio']);
    });

    test('sorts nearby results by computed distance', () {
      final result = applyExploreSearch(
        barbershops: [_imperio(distanceKm: 4), _navaja(distanceKm: 1.5)],
        services: const [],
        query: '',
        sort: ExploreSort.cercania,
      );

      expect(result.map((shop) => shop.id), ['navaja', 'imperio']);
    });
  });

  test('ExploreLoaded keeps selected custom radius', () {
    final state = ExploreLoaded(
      barbershops: const [],
      services: const [],
      markers: const [],
      favoriteIds: const [],
      currentSort: ExploreSort.cercania,
      userLat: 8.6,
      userLng: -82.9,
      userName: 'Client',
    ).copyWith(radiusKm: 25);

    expect(state.radiusKm, 25);
  });

  test('applyBarbershopDistances computes different distances from coordinates', () {
    final result = applyBarbershopDistances(
      shops: [_imperio(), _navaja()],
      userLat: 8.6,
      userLng: -82.9,
    );

    final imperio = result.firstWhere((shop) => shop.id == 'imperio');
    final navaja = result.firstWhere((shop) => shop.id == 'navaja');

    expect(imperio.distanceKm, isNotNull);
    expect(navaja.distanceKm, isNotNull);
    expect(imperio.distanceKm, isNot(equals(navaja.distanceKm)));
  });
}

BarbershopEntity _imperio({double? distanceKm}) {
  return BarbershopEntity(
    id: 'imperio',
    name: 'Imperio Barbershop',
    ownerName: 'Carlos Méndez',
    phone: '+506 8000 0000',
    address: 'Centro',
    lat: 8.6,
    lng: -82.9,
    rating: 4.8,
    reviewCount: 20,
    imageUrl: '',
    hasActivePromotion: false,
    tags: const ['fade'],
    barberNames: const ['Carlos Méndez'],
    distanceKm: distanceKm,
  );
}

BarbershopEntity _navaja({double? distanceKm}) {
  return BarbershopEntity(
    id: 'navaja',
    name: 'La Navaja de Oro',
    ownerName: 'Óscar Brenes',
    phone: '+506 8000 0001',
    address: 'Barrio Las Palmas',
    lat: 8.7,
    lng: -82.8,
    rating: 4.6,
    reviewCount: 15,
    imageUrl: '',
    hasActivePromotion: false,
    tags: const ['clasico'],
    barberNames: const ['Óscar Brenes'],
    distanceKm: distanceKm,
  );
}

ServiceExploreEntity _beardService() {
  return const ServiceExploreEntity(
    id: 'svc-1',
    barbershopId: 'imperio',
    barbershopSnapshot: BarbershopSnapshotEntity(
      name: 'Imperio Barbershop',
      imageUrl: '',
      rating: 4.8,
      address: 'Centro',
    ),
    serviceName: 'Arreglo de barba',
    description: 'Barba premium',
    price: 5000,
    durationMinutes: 30,
    category: 'barba',
    lat: 8.6,
    lng: -82.9,
  );
}
