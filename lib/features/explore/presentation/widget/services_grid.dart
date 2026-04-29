import 'package:flutter/material.dart';
import 'package:barberly/shared/theme/app_theme.dart';
import 'package:barberly/features/explore/presentation/bloc/service_model.dart';

import 'service_card.dart';

class ServicesGrid extends StatelessWidget {
  final List<ServiceModel> services;
  final String selectedCategory;

  const ServicesGrid({
    super.key,
    required this.services,
    required this.selectedCategory,
  });

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return _EmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(category: selectedCategory, count: services.length),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            return ServiceCard(
              service: services[index],
              onTap: () {
                // Navigation to detail screen handled by router
              },
            );
          },
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String category;
  final int count;

  const _SectionHeader({required this.category, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          category == 'Todos' ? 'Servicios Premium' : category,
          style: AppTypography.headlineSmall.copyWith(color: AppColors.onSurface),
        ),
        Text(
          '$count resultados',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: AppColors.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin resultados',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba con otra categoría o término',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
