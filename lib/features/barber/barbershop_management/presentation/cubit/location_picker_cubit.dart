import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'location_picker_state.dart';

class LocationPickerCubit extends Cubit<LocationPickerState> {
  LocationPickerCubit(LatLng initialLocation)
      : super(LocationPickerState(selectedLocation: initialLocation));

  Future<void> fetchCurrentLocation() async {
    emit(state.copyWith(isFetchingLocation: true, errorMessage: null));

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(state.copyWith(
          isFetchingLocation: false,
          errorMessage: 'Activa la ubicación del dispositivo',
        ));
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          emit(state.copyWith(
            isFetchingLocation: false,
            errorMessage: 'Permiso de ubicación denegado',
          ));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        emit(state.copyWith(
          isFetchingLocation: false,
          errorMessage: 'Permiso denegado permanentemente. Actívalo en configuración.',
        ));
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      emit(state.copyWith(
        isFetchingLocation: false,
        selectedLocation: LatLng(position.latitude, position.longitude),
        hasConfirmed: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isFetchingLocation: false,
        errorMessage: 'Error al obtener ubicación: $e',
      ));
    }
  }

  void confirmLocation(LatLng location) {
    emit(state.copyWith(
      selectedLocation: location,
      hasConfirmed: true,
      errorMessage: null,
    ));
  }

  void updatePreviewLocation(LatLng location) {
    emit(state.copyWith(selectedLocation: location, hasConfirmed: false));
  }

  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}
