import 'package:flutter/material.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../../domain/entities/barber.dart';

class BarbersList extends StatelessWidget {
  final List<Barber> barbers;
  final Barber? selected;
  final ValueChanged<Barber> onSelect;

  const BarbersList({
    super.key,
    required this.barbers,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final b in barbers) ...[
          _BarberTile(
            barber: b,
            selected: selected?.id == b.id,
            onTap: () => onSelect(b),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _BarberTile extends StatelessWidget {
  final Barber barber;
  final bool selected;
  final VoidCallback onTap;

  const _BarberTile({
    required this.barber,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryFixed
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryFixedDim,
              child: Icon(Icons.person, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Text(barber.name, style: AppTypography.titleSmall),
            const Spacer(),
            if (selected)
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}