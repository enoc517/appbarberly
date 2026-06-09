import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barberly/features/explore/data/models/explore_models.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Explore models', () {
    test('BarbershopModel reads coordinates from position.geopoint', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('barbershops').doc('shop-1').set({
        'name': 'Shop Uno',
        'ownerName': 'Owner Uno',
        'phone': '8888',
        'address': 'Centro',
        'position': {
          'geopoint': const GeoPoint(8.61, -82.95),
          'geohash': 'xyz',
        },
        'rating': 4.5,
        'reviewCount': 10,
        'imageUrl': '',
        'hasActivePromotion': false,
        'tags': ['fade'],
        'barberNames': ['Owner Uno'],
      });

      final snapshot = await firestore.collection('barbershops').doc('shop-1').get();
      final model = BarbershopModel.fromDocument(snapshot);

      expect(model.lat, 8.61);
      expect(model.lng, -82.95);
    });

    test('BarbershopModel falls back to lat/lng when position is missing', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('barbershops').doc('shop-2').set({
        'name': 'Shop Dos',
        'ownerName': 'Owner Dos',
        'phone': '9999',
        'address': 'Barrio',
        'lat': 8.62,
        'lng': -82.96,
        'rating': 4.7,
        'reviewCount': 8,
        'imageUrl': '',
        'hasActivePromotion': true,
        'tags': ['barba'],
        'barberNames': ['Owner Dos'],
      });

      final snapshot = await firestore.collection('barbershops').doc('shop-2').get();
      final model = BarbershopModel.fromDocument(snapshot);

      expect(model.lat, 8.62);
      expect(model.lng, -82.96);
    });

    test('ServiceExploreModel falls back to lat/lng when position is missing', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('services_explore').doc('svc-1').set({
        'barbershopId': 'shop-1',
        'barbershopSnapshot': {
          'name': 'Shop Uno',
          'imageUrl': '',
          'rating': 4.5,
          'address': 'Centro',
        },
        'serviceName': 'Corte',
        'description': 'Corte clásico',
        'price': 5000,
        'durationMinutes': 30,
        'category': 'corte',
        'lat': 8.63,
        'lng': -82.97,
      });

      final snapshot = await firestore.collection('services_explore').doc('svc-1').get();
      final model = ServiceExploreModel.fromDocument(snapshot);

      expect(model.lat, 8.63);
      expect(model.lng, -82.97);
    });
  });
}
