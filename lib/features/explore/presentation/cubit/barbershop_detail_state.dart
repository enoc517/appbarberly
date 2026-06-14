import 'package:equatable/equatable.dart';

import '../../../reviews/domain/entities/barbershop_review.dart';

class BarbershopDetailState extends Equatable {
  final bool isLoading;
  final Map<String, dynamic>? shop;
  final List<Map<String, dynamic>> members;
  final List<BarbershopReview> reviews;
  final bool isFavorite;
  final bool isUpdatingFavorite;
  final String? errorMessage;

  const BarbershopDetailState({
    this.isLoading = true,
    this.shop,
    this.members = const [],
    this.reviews = const [],
    this.isFavorite = false,
    this.isUpdatingFavorite = false,
    this.errorMessage,
  });

  BarbershopDetailState copyWith({
    bool? isLoading,
    Map<String, dynamic>? shop,
    List<Map<String, dynamic>>? members,
    List<BarbershopReview>? reviews,
    bool? isFavorite,
    bool? isUpdatingFavorite,
    String? errorMessage,
  }) {
    return BarbershopDetailState(
      isLoading: isLoading ?? this.isLoading,
      shop: shop ?? this.shop,
      members: members ?? this.members,
      reviews: reviews ?? this.reviews,
      isFavorite: isFavorite ?? this.isFavorite,
      isUpdatingFavorite: isUpdatingFavorite ?? this.isUpdatingFavorite,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    shop,
    members,
    reviews,
    isFavorite,
    isUpdatingFavorite,
    errorMessage,
  ];
}
