import 'package:equatable/equatable.dart';

import '../../domain/entities/barbershop_review.dart';

enum ReviewSortMode { recent, highestRated }

class BarbershopReviewsState extends Equatable {
  const BarbershopReviewsState({
    this.reviews = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.sortMode = ReviewSortMode.recent,
    this.errorMessage,
  });

  final List<BarbershopReview> reviews;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final ReviewSortMode sortMode;
  final String? errorMessage;

  BarbershopReviewsState copyWith({
    List<BarbershopReview>? reviews,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    ReviewSortMode? sortMode,
    String? errorMessage,
  }) {
    return BarbershopReviewsState(
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      sortMode: sortMode ?? this.sortMode,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    reviews,
    isLoading,
    isLoadingMore,
    hasMore,
    sortMode,
    errorMessage,
  ];
}
