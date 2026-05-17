import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/barbershop_management_repository.dart';
import '../../domain/usecases/create_barbershop.dart';
import '../../domain/usecases/get_barbershop_by_owner.dart';
import '../../domain/usecases/update_barbershop.dart';
import 'barbershop_management_state.dart';

class BarbershopManagementCubit extends Cubit<BarbershopManagementState> {
  final CreateBarbershop _createBarbershop;
  final UpdateBarbershop _updateBarbershop;
  final GetBarbershopByOwner _getBarbershopByOwner;

  BarbershopManagementCubit({
    required CreateBarbershop createBarbershop,
    required UpdateBarbershop updateBarbershop,
    required GetBarbershopByOwner getBarbershopByOwner,
  }) : _createBarbershop = createBarbershop,
       _updateBarbershop = updateBarbershop,
       _getBarbershopByOwner = getBarbershopByOwner,
       super(const BarbershopManagementInitial());

  Future<void> create(CreateBarbershopParams params) async {
    emit(const BarbershopManagementLoading());
    final result = await _createBarbershop(params);
    emit(result.when(
      ok: (shop) => BarbershopCreated(shop),
      fail: (f) => BarbershopManagementError(f.message),
    ));
  }

  Future<void> update(UpdateBarbershopParams params) async {
    emit(const BarbershopManagementLoading());
    final result = await _updateBarbershop(params);
    emit(result.when(
      ok: (shop) => BarbershopUpdated(shop),
      fail: (f) => BarbershopManagementError(f.message),
    ));
  }

  Future<void> load(String ownerId) async {
    emit(const BarbershopManagementLoading());
    final result = await _getBarbershopByOwner(ownerId);
    emit(result.when(
      ok: (shop) => BarbershopLoaded(shop),
      fail: (f) => BarbershopManagementError(f.message),
    ));
  }
}
