import '../../../reviews/domain/entities/barbershop_review.dart';

abstract class BarbershopDetailRepository {
  Future<BarbershopDetailData> getDetail(String shopId);
}

class BarbershopDetailData {
  final Map<String, dynamic>? shop;
  final List<Map<String, dynamic>> members;
  final List<BarbershopReview> reviews;

  const BarbershopDetailData({
    this.shop,
    this.members = const [],
    this.reviews = const [],
  });
}
