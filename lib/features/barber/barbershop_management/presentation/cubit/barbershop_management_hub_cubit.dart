import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'barbershop_management_hub_state.dart';

class BarbershopManagementHubCubit extends Cubit<BarbershopManagementHubState> {
  BarbershopManagementHubCubit() : super(const BarbershopManagementHubState());

  Future<void> loadBarbershopInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      emit(const BarbershopManagementHubState(isLoading: false));
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final db = FirebaseFirestore.instance;
      final uid = user.uid;

      final userDoc = await db.collection('users').doc(uid).get();
      final data = userDoc.data();
      final shopId = data?['barbershopId'] as String?;

      String? barbershopName;
      bool isOwner = false;
      bool hasBarbershop = false;

      if (shopId != null && shopId.isNotEmpty) {
        hasBarbershop = true;
        final memberDoc = await db
            .collection('barbershops')
            .doc(shopId)
            .collection('members')
            .doc(uid)
            .get();
        final memberData = memberDoc.data();
        barbershopName = memberData?['barberName'] as String?;
        isOwner = memberData?['role'] == 'owner';
      }

      emit(state.copyWith(
        isLoading: false,
        hasBarbershop: hasBarbershop,
        barbershopId: shopId,
        barbershopName: barbershopName,
        isOwner: isOwner,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}
