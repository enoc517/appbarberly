import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/events/barbershop_event_bus.dart';
import '../../../../auth/domain/usecases/get_current_user.dart';
import '../../domain/entities/favorite_barbershop_entry.dart';
import '../../domain/repositories/favorites_repository.dart';

sealed class FavoritesState {
  const FavoritesState();
}

class FavoritesLoading extends FavoritesState {
  const FavoritesLoading();
}

class FavoritesLoaded extends FavoritesState {
  const FavoritesLoaded(this.barbershops);

  final List<FavoriteBarbershopEntry> barbershops;
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
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required BarbershopEventBus eventBus,
    String? userId,
  }) : _repository = repository,
       _getCurrentUserUseCase = getCurrentUserUseCase,
       _eventBus = eventBus,
       _userId = userId,
       super(const FavoritesLoading()) {
    _eventSubscription = _eventBus.stream.listen((event) {
      if (event == BarbershopEvent.favoritesUpdated) {
        watch();
      }
    });
  }

  final FavoritesRepository _repository;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final BarbershopEventBus _eventBus;
  final String? _userId;
  StreamSubscription<List<FavoriteBarbershopEntry>>? _subscription;
  late final StreamSubscription<BarbershopEvent> _eventSubscription;

  Future<void> watch() async {
    final storedUserId = _userId;
    final userId = storedUserId == null || storedUserId.isEmpty
        ? await _resolveUserId()
        : storedUserId;
    if (userId == null || userId.isEmpty) {
      emit(const FavoritesEmpty());
      return;
    }

    await _subscription?.cancel();
    _subscription = _repository.watchFavoriteBarbershops(userId).listen(
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
    await _eventSubscription.cancel();
    return super.close();
  }

  Future<String?> _resolveUserId() async {
    final user = await _getCurrentUserUseCase();
    return user?.id;
  }
}
