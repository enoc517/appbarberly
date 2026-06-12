import '../entities/barbershop_review.dart';

abstract class ReviewsRepository {
  Future<String> createReview({
    required String bookingId,
    required String clientId,
    required int rating,
    String? comment,
  });

  Future<List<BarbershopReview>> getLatestReviews(
    String barbershopId, {
    int limit = 6,
  });

  Future<List<BarbershopReview>> getReviewsPage(
    String barbershopId, {
    int limit = 10,
    DateTime? startAfter,
  });
}
