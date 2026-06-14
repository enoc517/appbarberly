import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../client/favorites/domain/repositories/favorites_repository.dart';
import '../../domain/repositories/barbershop_detail_repository.dart';
import 'barbershop_detail_state.dart';

class BarbershopDetailCubit extends Cubit<BarbershopDetailState> {
  final String shopId;
  final String? userId;
  final BarbershopDetailRepository _repository;
  final FavoritesRepository _favoritesRepository;

  BarbershopDetailCubit({
    required this.shopId,
    required this.userId,
    required BarbershopDetailRepository repository,
    required FavoritesRepository favoritesRepository,
  }) : _repository = repository,
       _favoritesRepository = favoritesRepository,
       super(const BarbershopDetailState());

  Future<void> loadData() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final result = await _repository.getDetail(shopId);
      final favorite = await _isFavorite();

      emit(
        state.copyWith(
          isLoading: false,
          shop: result.shop,
          members: result.members,
          reviews: result.reviews,
          isFavorite: favorite,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  Future<void> toggleFavorite() async {
    final currentUserId = userId;
    if (currentUserId == null ||
        currentUserId.isEmpty ||
        state.isUpdatingFavorite) {
      return;
    }

    final previous = state.isFavorite;
    emit(state.copyWith(isFavorite: !previous, isUpdatingFavorite: true));

    try {
      if (previous) {
        await _favoritesRepository.removeFavorite(
          userId: currentUserId,
          barbershopId: shopId,
        );
      } else {
        await _favoritesRepository.addFavorite(
          userId: currentUserId,
          barbershopId: shopId,
        );
      }

      emit(state.copyWith(isUpdatingFavorite: false, errorMessage: null));
    } catch (e) {
      emit(
        state.copyWith(
          isFavorite: previous,
          isUpdatingFavorite: false,
          errorMessage: 'No se pudo actualizar el favorito: ${e.toString()}',
        ),
      );
    }
  }

  Future<bool> _isFavorite() async {
    final currentUserId = userId;
    if (currentUserId == null || currentUserId.isEmpty) return false;
    return _favoritesRepository.isFavorite(currentUserId, shopId);
  }
}
