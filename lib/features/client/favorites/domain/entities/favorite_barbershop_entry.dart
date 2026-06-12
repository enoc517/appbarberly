import 'package:equatable/equatable.dart';

import '../../../../explore/domain/entities/explore_entities.dart';

class FavoriteBarbershopEntry extends Equatable {
  const FavoriteBarbershopEntry({
    required this.shop,
    required this.addedAt,
    required this.bookingCount,
    this.lastBookedAt,
    this.lastServiceId,
    this.lastServiceName,
    this.lastBarberId,
    this.lastBarberName,
    this.isOpenNow,
    this.nextAvailableLabel,
  });

  final BarbershopEntity shop;
  final DateTime? addedAt;
  final DateTime? lastBookedAt;
  final String? lastServiceId;
  final String? lastServiceName;
  final String? lastBarberId;
  final String? lastBarberName;
  final int bookingCount;
  final bool? isOpenNow;
  final String? nextAvailableLabel;

  FavoriteBarbershopEntry copyWith({
    BarbershopEntity? shop,
    DateTime? addedAt,
    DateTime? lastBookedAt,
    String? lastServiceId,
    String? lastServiceName,
    String? lastBarberId,
    String? lastBarberName,
    int? bookingCount,
    bool? isOpenNow,
    String? nextAvailableLabel,
  }) {
    return FavoriteBarbershopEntry(
      shop: shop ?? this.shop,
      addedAt: addedAt ?? this.addedAt,
      lastBookedAt: lastBookedAt ?? this.lastBookedAt,
      lastServiceId: lastServiceId ?? this.lastServiceId,
      lastServiceName: lastServiceName ?? this.lastServiceName,
      lastBarberId: lastBarberId ?? this.lastBarberId,
      lastBarberName: lastBarberName ?? this.lastBarberName,
      bookingCount: bookingCount ?? this.bookingCount,
      isOpenNow: isOpenNow ?? this.isOpenNow,
      nextAvailableLabel: nextAvailableLabel ?? this.nextAvailableLabel,
    );
  }

  @override
  List<Object?> get props => [
    shop,
    addedAt,
    lastBookedAt,
    lastServiceId,
    lastServiceName,
    lastBarberId,
    lastBarberName,
    bookingCount,
    isOpenNow,
    nextAvailableLabel,
  ];
}
