import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'barbershop_detail_state.dart';

class BarbershopDetailCubit extends Cubit<BarbershopDetailState> {
  final String shopId;

  BarbershopDetailCubit({required this.shopId})
      : super(const BarbershopDetailState());

  Future<void> loadData() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final db = FirebaseFirestore.instance;

      final shopDoc = await db.collection('barbershops').doc(shopId).get();
      final membersSnapshot = await db
          .collection('barbershops')
          .doc(shopId)
          .collection('members')
          .orderBy('joinedAt')
          .get();

      emit(state.copyWith(
        isLoading: false,
        shop: shopDoc.data(),
        members: membersSnapshot.docs.map((d) => d.data()).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}
