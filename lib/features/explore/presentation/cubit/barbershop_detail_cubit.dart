import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/events/barbershop_event_bus.dart';
import '../../../auth/domain/usecases/get_current_user.dart';
import '../../../client/favorites/domain/repositories/favorites_repository.dart';
import '../../domain/repositories/barbershop_detail_repository.dart';
import 'barbershop_detail_state.dart';

class BarbershopDetailCubit extends Cubit<BarbershopDetailState> {
  final String shopId;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final BarbershopDetailRepository _repository;
  final FavoritesRepository _favoritesRepository;
  final BarbershopEventBus _eventBus;

  BarbershopDetailCubit({
    required this.shopId,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required BarbershopDetailRepository repository,
    required FavoritesRepository favoritesRepository,
    required BarbershopEventBus eventBus,
  }) : _repository = repository,
       _favoritesRepository = favoritesRepository,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       _eventBus = eventBus,
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
    final currentUserId = await _resolveUserId();
    if (currentUserId == null ||
        currentUserId.isEmpty ||
        state.isUpdatingFavorite) {
      emit(state.copyWith(errorMessage: 'Iniciá sesión para usar favoritos'));
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
      _eventBus.emit(BarbershopEvent.favoritesUpdated);
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
    final currentUserId = await _resolveUserId();
    if (currentUserId == null || currentUserId.isEmpty) return false;
    return _favoritesRepository.isFavorite(currentUserId, shopId);
  }

  Future<String?> _resolveUserId() async {
    final user = await _getCurrentUserUseCase();
    return user?.id;
  }
}
