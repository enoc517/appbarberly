import 'package:flutter/material.dart';
import '../../../../../shared/theme/app_theme.dart';

class BarbershopMap extends StatelessWidget {
  const BarbershopMap({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 140,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Center(
        child: Icon(Icons.location_on, size: 56, color: theme.colorScheme.secondary),
      ),
    );
  }
}