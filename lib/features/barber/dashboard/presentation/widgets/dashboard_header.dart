import 'package:flutter/material.dart';
import '/../../../shared/theme/app_theme.dart';

class DashboardHeader extends StatelessWidget {
  final DateTime today;
  const DashboardHeader({super.key, required this.today});

  static const _months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.cut,
                    color: AppColors.onPrimary, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Stitch & Style', style: AppTypography.titleLarge),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Panel del Barbero', style: AppTypography.headlineLarge),
          const SizedBox(height: 4),
          Text(
            'Resumen de actividad para hoy, ${today.day} de ${_months[today.month - 1]}',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}