import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/barbershop_detail_repository.dart';
import 'barbershop_detail_state.dart';

class BarbershopDetailCubit extends Cubit<BarbershopDetailState> {
  final String shopId;
  final BarbershopDetailRepository _repository;

  BarbershopDetailCubit({
    required this.shopId,
    required BarbershopDetailRepository repository,
  })  : _repository = repository,
        super(const BarbershopDetailState());

  Future<void> loadData() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final result = await _repository.getDetail(shopId);

      emit(state.copyWith(
        isLoading: false,
        shop: result.shop,
        members: result.members,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}
