import 'package:flutter/material.dart';
import '../../../../../shared/theme/app_theme.dart';

class BarbershopMap extends StatelessWidget {
  const BarbershopMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: const Center(
        child: Icon(Icons.location_on, size: 56, color: AppColors.secondary),
      ),
    );
  }
}