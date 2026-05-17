import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../membership/domain/usecases/leave_barbershop.dart';
import '../../../membership/data/datasources/membership_remote_datasource.dart';
import '../../../membership/data/repositories/membership_repository_impl.dart';
import 'barber_account_state.dart';

class BarberAccountCubit extends Cubit<BarberAccountState> {
  BarberAccountCubit() : super(const BarberAccountState());

  Future<void> loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

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
        userName: user.displayName ?? data?['fullName'] ?? 'Barbero',
        userEmail: user.email ?? '',
        hasBarbershop: hasBarbershop,
        barbershopId: shopId,
        barbershopName: barbershopName,
        isOwner: isOwner,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> leaveBarbershop() async {
    if (!state.hasBarbershop || state.barbershopId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final ds = MembershipRemoteDatasourceImpl(firestore: FirebaseFirestore.instance);
      final repo = MembershipRepositoryImpl(ds);
      final leaveUseCase = LeaveBarbershop(repo);

      final result = await leaveUseCase(LeaveBarbershopParams(
        barberId: user.uid,
        barbershopId: state.barbershopId!,
      ));

      result.when(
        ok: (_) => loadData(),
        fail: (f) => emit(state.copyWith(errorMessage: f.message)),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }
}
