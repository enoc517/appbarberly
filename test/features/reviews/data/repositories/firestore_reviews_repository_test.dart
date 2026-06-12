import 'package:barberly/features/bookings/domain/entities/booking.dart';
import 'package:barberly/features/reviews/data/repositories/firestore_reviews_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirestoreReviewsRepository', () {
    late FakeFirebaseFirestore firestore;
    late FirestoreReviewsRepository repository;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      repository = FirestoreReviewsRepository(firestore: firestore);
    });

    test('createReview stores review and updates aggregates', () async {
      await _seedCompletedBooking(firestore);
      await firestore.collection('barbershops').doc('shop-1').set({
        'rating': 4.0,
        'reviewCount': 2,
      });

      final reviewId = await repository.createReview(
        bookingId: 'booking-1',
        clientId: 'client-1',
        rating: 5,
        comment: 'Muy buen servicio',
      );

      expect(reviewId, 'booking-1');

      final reviewDoc = await firestore
          .collection('barbershops')
          .doc('shop-1')
          .collection('reviews')
          .doc('booking-1')
          .get();
      expect(reviewDoc.data()?['rating'], 5);
      expect(reviewDoc.data()?['comment'], 'Muy buen servicio');

      final shopDoc = await firestore.collection('barbershops').doc('shop-1').get();
      expect(shopDoc.data()?['reviewCount'], 3);
      expect(shopDoc.data()?['rating'], closeTo(4.333333, 0.0001));

      final bookingDoc = await firestore.collection('bookings').doc('booking-1').get();
      expect(bookingDoc.data()?['reviewId'], 'booking-1');
      expect(bookingDoc.data()?['reviewedAt'], isNotNull);
    });

    test('createReview rejects incomplete bookings', () async {
      await firestore.collection('bookings').doc('booking-1').set({
        'clientId': 'client-1',
        'barberId': 'barber-1',
        'barbershopId': 'shop-1',
        'status': AppointmentBookingStatus.confirmed.name,
        'clientSnapshot': {'name': 'Cliente'},
        'barberSnapshot': {'name': 'Barbero'},
        'serviceSnapshot': {'name': 'Corte'},
      });

      await expectLater(
        repository.createReview(
          bookingId: 'booking-1',
          clientId: 'client-1',
          rating: 4,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}

Future<void> _seedCompletedBooking(FakeFirebaseFirestore firestore) async {
  await firestore.collection('bookings').doc('booking-1').set({
    'clientId': 'client-1',
    'barberId': 'barber-1',
    'barbershopId': 'shop-1',
    'serviceId': 'service-1',
    'status': AppointmentBookingStatus.completed.name,
    'clientSnapshot': {'name': 'Cliente', 'imageUrl': ''},
    'barberSnapshot': {'name': 'Barbero', 'imageUrl': ''},
    'serviceSnapshot': {'name': 'Corte', 'imageUrl': ''},
  });
}
