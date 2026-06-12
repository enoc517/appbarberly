import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/barbershop_review.dart';
import '../../domain/repositories/reviews_repository.dart';
import 'barbershop_reviews_state.dart';

class BarbershopReviewsCubit extends Cubit<BarbershopReviewsState> {
  BarbershopReviewsCubit({
    required String barbershopId,
    required ReviewsRepository repository,
  })  : _barbershopId = barbershopId,
        _repository = repository,
        super(const BarbershopReviewsState());

  final String _barbershopId;
  final ReviewsRepository _repository;
  DateTime? _cursor;

  Future<void> load() async {
    if (_barbershopId.trim().isEmpty) {
      emit(const BarbershopReviewsState(isLoading: false, hasMore: false));
      return;
    }

    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final page = await _repository.getReviewsPage(_barbershopId);
      emit(
        state.copyWith(
          isLoading: false,
          reviews: _applySort(page, state.sortMode),
          hasMore: page.length == 10,
        ),
      );
      _cursor = page.isEmpty ? null : page.last.createdAt;
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: 'No se pudieron cargar las reseñas'));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    if (_barbershopId.trim().isEmpty || _cursor == null) return;

    emit(state.copyWith(isLoadingMore: true, errorMessage: null));
    try {
      final page = await _repository.getReviewsPage(
        _barbershopId,
        startAfter: _cursor,
      );
      emit(
        state.copyWith(
          isLoadingMore: false,
          reviews: _applySort([...state.reviews, ...page], state.sortMode),
          hasMore: page.length == 10,
        ),
      );
      _cursor = page.isEmpty ? _cursor : page.last.createdAt;
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false, errorMessage: 'No se pudieron cargar más reseñas'));
    }
  }

  void setSortMode(ReviewSortMode mode) {
    if (state.sortMode == mode) return;
    emit(
      state.copyWith(
        sortMode: mode,
        reviews: _applySort(state.reviews, mode),
        errorMessage: null,
      ),
    );
  }

  List<BarbershopReview> _applySort(
    List<BarbershopReview> reviews,
    ReviewSortMode mode,
  ) {
    final sorted = [...reviews];
    switch (mode) {
      case ReviewSortMode.recent:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ReviewSortMode.highestRated:
        sorted.sort((a, b) {
          final ratingCompare = b.rating.compareTo(a.rating);
          if (ratingCompare != 0) return ratingCompare;
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
    }
    return sorted;
  }
}
