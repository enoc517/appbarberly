import 'package:flutter/material.dart';
import '/../../../shared/motion/app_motion.dart';
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
    final theme = Theme.of(context);
    final reduced = AppMotion.reduceMotion(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
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
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: reduced ? completed.toDouble() : 0,
                    end: completed.toDouble(),
                  ),
                  duration: reduced ? Duration.zero : AppMotion.entrance,
                  curve: AppMotion.standard,
                  builder: (context, value, child) => RichText(
                    text: TextSpan(
                      style: AppTypography.displaySmall.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                      children: [
                        TextSpan(
                          text: value.round().toString().padLeft(2, '0'),
                        ),
                        TextSpan(
                          text: ' / $total',
                          style: AppTypography.titleMedium.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            height: 32,
            child: Stack(
              children: [
                Positioned(
                  right: 20,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primaryFixedDim,
                    child: const Icon(Icons.person, size: 16),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(
                      Icons.person,
                      size: 16,
                      color: theme.colorScheme.onPrimary,
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
