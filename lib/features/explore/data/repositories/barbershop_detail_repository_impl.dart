import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/barbershop_detail_repository.dart';

class BarbershopDetailRepositoryImpl implements BarbershopDetailRepository {
  BarbershopDetailRepositoryImpl({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

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

    return BarbershopDetailData(
      shop: shopDoc.data(),
      members: membersSnapshot.docs.map((d) => d.data()).toList(),
    );
  }
}
