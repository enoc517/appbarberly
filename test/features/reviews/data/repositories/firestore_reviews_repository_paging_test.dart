import 'package:barberly/features/reviews/data/repositories/firestore_reviews_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('getReviewsPage returns reviews ordered by newest first', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreReviewsRepository(firestore: firestore);

    final reviews = firestore.collection('barbershops').doc('shop-1').collection('reviews');
    await reviews.doc('r1').set({
      'createdAt': DateTime(2026, 6, 1),
      'rating': 4,
      'clientSnapshot': {'name': 'A'},
      'barberSnapshot': {'name': 'B'},
      'serviceSnapshot': {'name': 'C'},
    });
    await reviews.doc('r2').set({
      'createdAt': DateTime(2026, 6, 2),
      'rating': 5,
      'clientSnapshot': {'name': 'A'},
      'barberSnapshot': {'name': 'B'},
      'serviceSnapshot': {'name': 'C'},
    });

    final page = await repository.getReviewsPage('shop-1', limit: 2);

    expect(page.map((r) => r.id).toList(), ['r2', 'r1']);
  });
}
