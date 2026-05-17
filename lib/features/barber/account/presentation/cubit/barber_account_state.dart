import 'package:equatable/equatable.dart';

class BarberAccountState extends Equatable {
  final bool isLoading;
  final String? userName;
  final String? userEmail;
  final bool hasBarbershop;
  final String? barbershopId;
  final String? barbershopName;
  final bool isOwner;
  final String? errorMessage;

  const BarberAccountState({
    this.isLoading = true,
    this.userName,
    this.userEmail,
    this.hasBarbershop = false,
    this.barbershopId,
    this.barbershopName,
    this.isOwner = false,
    this.errorMessage,
  });

  BarberAccountState copyWith({
    bool? isLoading,
    String? userName,
    String? userEmail,
    bool? hasBarbershop,
    String? barbershopId,
    String? barbershopName,
    bool? isOwner,
    String? errorMessage,
  }) {
    return BarberAccountState(
      isLoading: isLoading ?? this.isLoading,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
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
        userName,
        userEmail,
        hasBarbershop,
        barbershopId,
        barbershopName,
        isOwner,
        errorMessage,
      ];
}
