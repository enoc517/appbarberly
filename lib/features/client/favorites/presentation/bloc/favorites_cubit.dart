import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../explore/domain/entities/explore_entities.dart';
import '../../domain/repositories/favorites_repository.dart';

sealed class FavoritesState {
  const FavoritesState();
}

class FavoritesLoading extends FavoritesState {
  const FavoritesLoading();
}

class FavoritesLoaded extends FavoritesState {
  const FavoritesLoaded(this.barbershops);

  final List<BarbershopEntity> barbershops;
}

class FavoritesEmpty extends FavoritesState {
  const FavoritesEmpty();
}

class FavoritesError extends FavoritesState {
  const FavoritesError(this.message);

  final String message;
}

class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit({
    required FavoritesRepository repository,
    required String userId,
  }) : _repository = repository,
       _userId = userId,
       super(const FavoritesLoading());

  final FavoritesRepository _repository;
  final String _userId;
  StreamSubscription<List<BarbershopEntity>>? _subscription;

  void watch() {
    if (_userId.isEmpty) {
      emit(const FavoritesEmpty());
      return;
    }

    _subscription?.cancel();
    _subscription = _repository.watchFavoriteBarbershops(_userId).listen(
      (barbershops) {
        emit(
          barbershops.isEmpty
              ? const FavoritesEmpty()
              : FavoritesLoaded(barbershops),
        );
      },
      onError: (_) =>
          emit(const FavoritesError('No se pudieron cargar tus favoritos')),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
