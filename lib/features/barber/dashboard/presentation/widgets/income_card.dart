import 'package:flutter/material.dart';
import '/../../../shared/theme/app_theme.dart';

class IncomeCard extends StatelessWidget {
  final double income;
  final double deltaPercent;

  const IncomeCard({
    super.key,
    required this.income,
    required this.deltaPercent,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = deltaPercent >= 0;
    final sign = isPositive ? '+' : '';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined,
                  color: AppColors.secondary, size: 24),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.onPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$sign${deltaPercent.toStringAsFixed(0)}% vs ayer',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          Text(
            'INGRESOS DE HOY',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.onPrimaryContainer,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${income.toStringAsFixed(2)}',
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}