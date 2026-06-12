import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../bookings/domain/entities/booking.dart';
import '../../domain/entities/barbershop_review.dart';
import '../../domain/repositories/reviews_repository.dart';

class FirestoreReviewsRepository implements ReviewsRepository {
  FirestoreReviewsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('bookings');

  @override
  Future<String> createReview({
    required String bookingId,
    required String clientId,
    required int rating,
    String? comment,
  }) async {
    if (bookingId.trim().isEmpty) {
      throw StateError('La cita no es válida.');
    }
    if (clientId.trim().isEmpty) {
      throw StateError('El cliente no es válido.');
    }
    if (rating < 1 || rating > 5) {
      throw StateError('El rating debe estar entre 1 y 5.');
    }

    final bookingRef = _bookings.doc(bookingId);

    await _db.runTransaction((transaction) async {
      final bookingSnapshot = await transaction.get(bookingRef);
      final bookingData = bookingSnapshot.data();
      if (bookingData == null) {
        throw StateError('La cita ya no existe.');
      }

      if ((bookingData['clientId'] as String? ?? '') != clientId) {
        throw StateError('No puedes reseñar una cita que no es tuya.');
      }

      final status = _bookingStatus(bookingData['status'] as String?);
      if (status != AppointmentBookingStatus.completed) {
        throw StateError('Solo puedes reseñar citas completadas.');
      }

      final barbershopId = bookingData['barbershopId'] as String? ?? '';
      if (barbershopId.isEmpty) {
        throw StateError('La barbería no es válida.');
      }

      final reviewRef = _db
          .collection('barbershops')
          .doc(barbershopId)
          .collection('reviews')
          .doc(bookingId);

      final reviewSnapshot = await transaction.get(reviewRef);
      if (reviewSnapshot.exists) {
        throw StateError('Esta cita ya tiene una reseña.');
      }

      final shopRef = _db.collection('barbershops').doc(barbershopId);
      final shopSnapshot = await transaction.get(shopRef);
      final shopData = shopSnapshot.data() ?? <String, dynamic>{};
      final currentRating = (shopData['rating'] as num?)?.toDouble() ?? 0.0;
      final currentCount = (shopData['reviewCount'] as num?)?.toInt() ?? 0;
      final nextCount = currentCount + 1;
      final nextRating = ((currentRating * currentCount) + rating) / nextCount;

      final reviewData = <String, dynamic>{
        'bookingId': bookingId,
        'clientId': clientId,
        'barberId': bookingData['barberId'] as String? ?? '',
        'barbershopId': barbershopId,
        'rating': rating,
        'comment': _normalizeComment(comment),
        'createdAt': FieldValue.serverTimestamp(),
        'clientSnapshot': bookingData['clientSnapshot'],
        'barberSnapshot': bookingData['barberSnapshot'],
        'serviceSnapshot': bookingData['serviceSnapshot'],
      };

      transaction.set(reviewRef, reviewData);
      transaction.update(shopRef, {
        'rating': nextRating,
        'reviewCount': nextCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(bookingRef, {
        'reviewId': reviewRef.id,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return bookingId;
  }

  @override
  Future<List<BarbershopReview>> getLatestReviews(
    String barbershopId, {
    int limit = 6,
  }) async {
    final reviews = await getReviewsPage(barbershopId, limit: limit);
    return reviews;
  }

  @override
  Future<List<BarbershopReview>> getReviewsPage(
    String barbershopId, {
    int limit = 10,
    DateTime? startAfter,
  }) async {
    if (barbershopId.trim().isEmpty) return const [];

    Query<Map<String, dynamic>> query = _db
        .collection('barbershops')
        .doc(barbershopId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfter([Timestamp.fromDate(startAfter)]);
    }

    final snapshot = await query.get();
    return snapshot.docs.map(_fromDocument).toList(growable: false);
  }

  BarbershopReview _fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return BarbershopReview(
      id: doc.id,
      bookingId: data['bookingId'] as String? ?? doc.id,
      clientId: data['clientId'] as String? ?? '',
      barberId: data['barberId'] as String? ?? '',
      barbershopId: data['barbershopId'] as String? ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      comment: data['comment'] as String?,
      createdAt: _dateTime(data['createdAt']),
      clientSnapshot: _snapshot(data['clientSnapshot']),
      barberSnapshot: _snapshot(data['barberSnapshot']),
      serviceSnapshot: _snapshot(data['serviceSnapshot']),
    );
  }

  static BookingSnapshot _snapshot(Object? value) {
    final map = value is Map<String, dynamic> ? value : <String, dynamic>{};
    return BookingSnapshot(
      name: map['name'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
    );
  }

  static DateTime _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static AppointmentBookingStatus _bookingStatus(String? value) {
    return AppointmentBookingStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => AppointmentBookingStatus.pending,
    );
  }

  static String? _normalizeComment(String? comment) {
    final trimmed = comment?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
