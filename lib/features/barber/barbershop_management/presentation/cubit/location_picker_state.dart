import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerState extends Equatable {
  final LatLng selectedLocation;
  final bool isFetchingLocation;
  final bool hasConfirmed;
  final String? errorMessage;

  const LocationPickerState({
    this.selectedLocation = const LatLng(8.6135, -82.9589),
    this.isFetchingLocation = false,
    this.hasConfirmed = false,
    this.errorMessage,
  });

  LocationPickerState copyWith({
    LatLng? selectedLocation,
    bool? isFetchingLocation,
    bool? hasConfirmed,
    String? errorMessage,
  }) {
    return LocationPickerState(
      selectedLocation: selectedLocation ?? this.selectedLocation,
      isFetchingLocation: isFetchingLocation ?? this.isFetchingLocation,
      hasConfirmed: hasConfirmed ?? this.hasConfirmed,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [selectedLocation, isFetchingLocation, hasConfirmed, errorMessage];
}
