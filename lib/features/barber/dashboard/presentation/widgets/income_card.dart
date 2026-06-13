import 'package:flutter/material.dart';
import '/../../../shared/motion/app_motion.dart';
import '/../../../shared/theme/app_theme.dart';

class IncomeCard extends StatelessWidget {
  final double income;
  final double deltaPercent;
  final double? estimatedIncome;

  const IncomeCard({
    super.key,
    required this.income,
    required this.deltaPercent,
    this.estimatedIncome,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = deltaPercent >= 0;
    final sign = isPositive ? '+' : '';
    final reduced = AppMotion.reduceMotion(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                color: theme.colorScheme.onPrimary,
                size: 24,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$sign${deltaPercent.toStringAsFixed(0)}% vs ayer',
                  style: AppTypography.labelSmall.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Text(
            'INGRESOS DE HOY',
            style: AppTypography.labelMedium.copyWith(
              color: theme.colorScheme.onPrimary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: reduced ? income : 0, end: income),
            duration: reduced ? Duration.zero : AppMotion.entrance,
            curve: AppMotion.standard,
            builder: (context, value, child) => Text(
              '\$${value.toStringAsFixed(2)}',
              style: AppTypography.displaySmall.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (estimatedIncome != null) ...[
            const SizedBox(height: 8),
            Text(
              'Estimado: \$${estimatedIncome!.toStringAsFixed(2)}',
              style: AppTypography.labelLarge.copyWith(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
