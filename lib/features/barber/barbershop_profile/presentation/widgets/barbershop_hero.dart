import 'package:flutter/material.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../../domain/entities/barbershop.dart';

class BarbershopHero extends StatelessWidget {
  final Barbershop barbershop;
  final VoidCallback onCheckIn;

  const BarbershopHero({
    super.key,
    required this.barbershop,
    required this.onCheckIn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            Container(
              height: 180,
              width: double.infinity,
              color: theme.colorScheme.inverseSurface,
              child: Icon(
                Icons.storefront,
                size: 64,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      theme.colorScheme.primary.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    barbershop.name,
                    style: AppTypography.headlineMedium.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: theme.colorScheme.onPrimary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        barbershop.district,
                        style: AppTypography.bodySmall.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: FilledButton.icon(
                onPressed: onCheckIn,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.check_circle, size: 18),
                label: const Text('Registrar llegada'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}