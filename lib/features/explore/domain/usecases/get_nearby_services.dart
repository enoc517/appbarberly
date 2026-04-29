import 'package:barberly/features/explore/domain/entities/explore_entities.dart';
import 'package:barberly/features/explore/domain/repositories/explore_repository.dart';

class GetNearbyServices {
  final ExploreRepository repository;

  GetNearbyServices(this.repository);

  // El método 'call' permite ejecutar la clase como si fuera una función
  Stream<List<ServiceExploreEntity>> call({
    required double lat,
    required double lng,
    double radiusKm = 10,
    String? category,
  }) {
    return repository.getNearbyServices(
      lat: lat,
      lng: lng,
      radiusKm: radiusKm,
      category: category,
    );
  }
}
