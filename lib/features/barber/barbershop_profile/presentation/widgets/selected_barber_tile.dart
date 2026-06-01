import 'package:flutter/material.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../../domain/entities/barber.dart';

class SelectedBarberTile extends StatelessWidget {
  final Barber? barber;

  const SelectedBarberTile({super.key, required this.barber});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryFixedDim,
            child: Icon(Icons.person, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BARBERO SELECCIONADO',
                style: AppTypography.labelSmall.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                barber?.name ?? 'Sin seleccionar',
                style: AppTypography.titleSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}