import 'package:equatable/equatable.dart';

class BarbershopManagementHubState extends Equatable {
  final bool isLoading;
  final bool hasBarbershop;
  final String? barbershopId;
  final String? barbershopName;
  final bool isOwner;
  final String? errorMessage;

  const BarbershopManagementHubState({
    this.isLoading = true,
    this.hasBarbershop = false,
    this.barbershopId,
    this.barbershopName,
    this.isOwner = false,
    this.errorMessage,
  });

  BarbershopManagementHubState copyWith({
    bool? isLoading,
    bool? hasBarbershop,
    String? barbershopId,
    String? barbershopName,
    bool? isOwner,
    String? errorMessage,
  }) {
    return BarbershopManagementHubState(
      isLoading: isLoading ?? this.isLoading,
      hasBarbershop: hasBarbershop ?? this.hasBarbershop,
      barbershopId: barbershopId ?? this.barbershopId,
      barbershopName: barbershopName ?? this.barbershopName,
      isOwner: isOwner ?? this.isOwner,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        hasBarbershop,
        barbershopId,
        barbershopName,
        isOwner,
        errorMessage,
      ];
}
