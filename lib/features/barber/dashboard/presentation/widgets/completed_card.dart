import 'package:flutter/material.dart';
import '/../../../shared/theme/app_theme.dart';

class CompletedCard extends StatelessWidget {
  final int completed;
  final int total;

  const CompletedCard({
    super.key,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline, size: 28),
                const SizedBox(height: 12),
                Text(
                  'CITAS COMPLETADAS',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: AppTypography.displaySmall.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                    children: [
                      TextSpan(text: completed.toString().padLeft(2, '0')),
                      TextSpan(
                        text: ' / $total',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Avatares superpuestos decorativos (placeholder)
          SizedBox(
            width: 60,
            height: 32,
            child: Stack(
              children: const [
                Positioned(
                  right: 20,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primaryFixedDim,
                    child: Icon(Icons.person, size: 16),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary,
                    child: Icon(
                      Icons.person,
                      size: 16,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}