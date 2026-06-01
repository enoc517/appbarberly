import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/barbershop_hub_repository.dart';

class BarbershopHubRepositoryImpl implements BarbershopHubRepository {
  BarbershopHubRepositoryImpl({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<BarbershopHubInfo> getHubInfo(String userId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    final data = userDoc.data();
    final shopId = data?['barbershopId'] as String?;

    if (shopId == null || shopId.isEmpty) {
      return const BarbershopHubInfo();
    }

    final memberDoc = await _db
        .collection('barbershops')
        .doc(shopId)
        .collection('members')
        .doc(userId)
        .get();
    final memberData = memberDoc.data();
    final shopDoc = await _db.collection('barbershops').doc(shopId).get();
    final shopData = shopDoc.data();

    return BarbershopHubInfo(
      hasBarbershop: true,
      barbershopId: shopId,
      barbershopName: shopData?['name'] as String?,
      isOwner: memberData?['role'] == 'owner',
    );
  }
}
