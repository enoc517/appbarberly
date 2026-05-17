import 'package:equatable/equatable.dart';

class BarbershopDetailState extends Equatable {
  final bool isLoading;
  final Map<String, dynamic>? shop;
  final List<Map<String, dynamic>> members;
  final String? errorMessage;

  const BarbershopDetailState({
    this.isLoading = true,
    this.shop,
    this.members = const [],
    this.errorMessage,
  });

  BarbershopDetailState copyWith({
    bool? isLoading,
    Map<String, dynamic>? shop,
    List<Map<String, dynamic>>? members,
    String? errorMessage,
  }) {
    return BarbershopDetailState(
      isLoading: isLoading ?? this.isLoading,
      shop: shop ?? this.shop,
      members: members ?? this.members,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, shop, members, errorMessage];
}
