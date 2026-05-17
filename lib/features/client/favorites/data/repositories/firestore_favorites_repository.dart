import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../explore/data/models/explore_models.dart';
import '../../../../explore/domain/entities/explore_entities.dart';
import '../../domain/repositories/favorites_repository.dart';

class FirestoreFavoritesRepository implements FavoritesRepository {
  FirestoreFavoritesRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Stream<List<BarbershopEntity>> watchFavoriteBarbershops(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final ids = snapshot.docs.map((doc) => doc.id).toList();
          if (ids.isEmpty) return const <BarbershopEntity>[];

          final chunks = <List<String>>[];
          for (var i = 0; i < ids.length; i += 10) {
            chunks.add(
              ids.sublist(i, i + 10 > ids.length ? ids.length : i + 10),
            );
          }

          final shops = <BarbershopEntity>[];
          for (final chunk in chunks) {
            final query = await _db
                .collection('barbershops')
                .where(FieldPath.documentId, whereIn: chunk)
                .get();
            shops.addAll(
              query.docs.map(
                (doc) => BarbershopModel.fromDocument(doc).toEntity(),
              ),
            );
          }

          final byId = {for (final shop in shops) shop.id: shop};
          return ids
              .map((id) => byId[id])
              .whereType<BarbershopEntity>()
              .toList();
        });
  }
}
