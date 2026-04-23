import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_barbershop.dart';
import 'barbershop_profile_state.dart';

class BarbershopProfileCubit extends Cubit<BarbershopProfileState> {
  final GetBarbershop _getBarbershop;

  BarbershopProfileCubit(this._getBarbershop)
      : super(const BarbershopProfileLoading());

  Future<void> load(String id) async {
    emit(const BarbershopProfileLoading());
    final result = await _getBarbershop(id);
    emit(result.when(
      ok: (shop) => BarbershopProfileLoaded(shop),
      fail: (f) => BarbershopProfileError(f.message),
    ));
  }
}