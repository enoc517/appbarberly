import '../../../../explore/domain/entities/explore_entities.dart';

abstract class FavoritesRepository {
  Stream<List<BarbershopEntity>> watchFavoriteBarbershops(String userId);
}
