import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../shared/theme/app_theme.dart';
import '../cubit/location_picker_cubit.dart';
import '../cubit/location_picker_state.dart';

class LocationPicker extends StatelessWidget {
  final LatLng initialLocation;
  final ValueChanged<LatLng> onLocationSelected;

  const LocationPicker({
    super.key,
    required this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LocationPickerCubit(initialLocation),
      child: _LocationPickerView(onLocationSelected: onLocationSelected),
    );
  }
}

class _LocationPickerView extends StatelessWidget {
  final ValueChanged<LatLng> onLocationSelected;

  const _LocationPickerView({required this.onLocationSelected});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LocationPickerCubit>();

    return BlocConsumer<LocationPickerCubit, LocationPickerState>(
      listener: (context, state) {
        if (state.hasConfirmed) {
          onLocationSelected(state.selectedLocation);
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
          cubit.clearError();
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel(text: 'Ubicación en el mapa'),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: state.selectedLocation,
                        initialZoom: 15,
                        onPositionChanged: (position, hasGesture) {
                          if (hasGesture) {
                            cubit.updatePreviewLocation(position.center);
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.proyectomoviles.barberly',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: state.selectedLocation,
                              child: const Icon(
                                Icons.location_on_rounded,
                                size: 48,
                                color: AppColors.secondary,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Material(
                        color: AppColors.surfaceContainerLowest,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: state.isFetchingLocation
                              ? null
                              : () => cubit.fetchCurrentLocation(),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: state.isFetchingLocation
                                ? const Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : const Icon(Icons.my_location_rounded),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _CoordinatesDisplay(location: state.selectedLocation),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  cubit.confirmLocation(state.selectedLocation);
                },
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Seleccionar esta ubicación'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CoordinatesDisplay extends StatelessWidget {
  final LatLng location;
  const _CoordinatesDisplay({required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on_rounded, size: 18, color: AppColors.outline),
          const SizedBox(width: 8),
          Text(
            '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelLarge.copyWith(
        color: AppColors.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}
