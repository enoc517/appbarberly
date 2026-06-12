import 'package:barberly/features/client/favorites/data/repositories/firestore_favorites_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestoreFavoritesRepository', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreFavoritesRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = FirestoreFavoritesRepository(firestore: firestore);
    });

    test('watchFavoriteBarbershops sorts by latest booking first', () async {
      await _seedShop(firestore, 'shop-a', 'A');
      await _seedShop(firestore, 'shop-b', 'B');

      await firestore.collection('users').doc('user-1').collection('favorites').doc('shop-a').set({
        'barbershopId': 'shop-a',
        'addedAt': DateTime(2026, 6, 1),
      });
      await firestore.collection('users').doc('user-1').collection('favorites').doc('shop-b').set({
        'barbershopId': 'shop-b',
        'addedAt': DateTime(2026, 6, 2),
      });

      final entries = await repository.watchFavoriteBarbershops('user-1').first;

      expect(entries.map((e) => e.shop.id).toList(), ['shop-b', 'shop-a']);
    });

    test('recordFavoriteBooking updates metadata only when favorite exists', () async {
      await _seedShop(firestore, 'shop-a', 'A');
      await firestore.collection('users').doc('user-1').collection('favorites').doc('shop-a').set({
        'barbershopId': 'shop-a',
        'addedAt': DateTime(2026, 6, 1),
        'bookingCount': 1,
      });

      await repository.recordFavoriteBooking(
        userId: 'user-1',
        barbershopId: 'shop-a',
        bookedAt: DateTime(2026, 6, 5, 10, 30),
        serviceId: 'svc-1',
        serviceName: 'Corte',
        barberId: 'barber-1',
        barberName: 'Ana',
      );

      final doc = await firestore
          .collection('users')
          .doc('user-1')
          .collection('favorites')
          .doc('shop-a')
          .get();

      expect(doc.data()?['bookingCount'], 2);
      expect(doc.data()?['lastServiceName'], 'Corte');
      expect(doc.data()?['lastBarberName'], 'Ana');
    });
  });
}

Future<void> _seedShop(
  FakeFirebaseFirestore firestore,
  String shopId,
  String name,
) async {
  await firestore.collection('barbershops').doc(shopId).set({
    'name': name,
    'ownerName': 'Owner $name',
    'phone': '0000',
    'address': 'Address $name',
    'lat': 0,
    'lng': 0,
    'rating': 4.5,
    'reviewCount': 10,
    'imageUrl': '',
    'hasActivePromotion': false,
    'tags': const [],
    'barberNames': ['Barber $name'],
  });
}
