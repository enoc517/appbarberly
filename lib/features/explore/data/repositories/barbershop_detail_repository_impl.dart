import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/barbershop_detail_repository.dart';
import '../../../reviews/domain/repositories/reviews_repository.dart';

class BarbershopDetailRepositoryImpl implements BarbershopDetailRepository {
  BarbershopDetailRepositoryImpl({
    FirebaseFirestore? firestore,
    required ReviewsRepository reviewsRepository,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _reviewsRepository = reviewsRepository;

  final FirebaseFirestore _db;
  final ReviewsRepository _reviewsRepository;

  @override
  Future<BarbershopDetailData> getDetail(String shopId) async {
    final shopDoc =
        await _db.collection('barbershops').doc(shopId).get();
    final membersSnapshot = await _db
        .collection('barbershops')
        .doc(shopId)
        .collection('members')
        .orderBy('joinedAt')
        .get();

    final members = await Future.wait(
      membersSnapshot.docs.map((doc) => _enrichMember(doc)),
    );

    final reviews = await _reviewsRepository.getLatestReviews(shopId);

    return BarbershopDetailData(
      shop: shopDoc.data(),
      members: members,
      reviews: reviews,
    );
  }

  Future<Map<String, dynamic>> _enrichMember(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = Map<String, dynamic>.from(doc.data());
    final barberId = data['barberId'] as String? ?? doc.id;
    final avatarUrl = data['barberAvatarUrl'] as String?;

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return data;
    }

    final userDoc = await _db.collection('users').doc(barberId).get();
    final userAvatarUrl = userDoc.data()?['profileImageUrl'] as String?;
    if (userAvatarUrl != null && userAvatarUrl.isNotEmpty) {
      data['barberAvatarUrl'] = userAvatarUrl;
    }

    return data;
  }
}
