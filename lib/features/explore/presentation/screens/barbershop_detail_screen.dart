import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/motion/app_motion.dart';
import '../cubit/barbershop_detail_cubit.dart';
import '../cubit/barbershop_detail_state.dart';

class BarbershopDetailScreen extends StatelessWidget {
  final String shopId;

  const BarbershopDetailScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BarbershopDetailCubit(shopId: shopId)..loadData(),
      child: const _BarbershopDetailView(),
    );
  }
}

class _BarbershopDetailView extends StatelessWidget {
  const _BarbershopDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<BarbershopDetailCubit, BarbershopDetailState>(
        buildWhen: (prev, curr) => prev.isLoading != curr.isLoading,
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.shop == null) {
            return Center(
              child: Text(
                'Barbería no encontrada',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            );
          }
          return _DetailContent(shop: state.shop!, members: state.members);
        },
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final Map<String, dynamic> shop;
  final List<Map<String, dynamic>> members;

  const _DetailContent({required this.shop, required this.members});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppFadeSlideIn(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Container(
                height: 200,
                width: double.infinity,
                color: AppColors.surfaceContainerHighest,
                child: (shop['imageUrl'] as String?)?.isNotEmpty == true
                    ? Image.network(shop['imageUrl']!, fit: BoxFit.cover)
                    : Icon(Icons.storefront_rounded, size: 64, color: AppColors.outline),
              ),
            ),
          ),
          const SizedBox(height: 20),
          AppFadeSlideIn(
            delay: AppMotion.delay(1),
            child: Text(
              shop['name'] as String? ?? '',
              style: AppTypography.headlineMedium.copyWith(color: AppColors.onSurface),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.star_rounded, size: 18, color: AppColors.secondary),
              const SizedBox(width: 4),
              Text(
                '${shop['rating'] ?? 0} (${shop['reviewCount'] ?? 0} reseñas)',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 18, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  shop['address'] as String? ?? '',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (shop['tags'] as List<dynamic>?)
                    ?.map((t) => Chip(
                          label: Text(t.toString(),
                              style: AppTypography.labelSmall.copyWith(color: AppColors.onPrimary)),
                          backgroundColor: AppColors.primaryContainer,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                        ))
                    .toList() ??
                [],
          ),
          const SizedBox(height: 28),
          Text(
            'Barberos',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          if (members.isEmpty)
            Text(
              'No hay barberos aún',
              style: AppTypography.bodyLarge.copyWith(color: AppColors.onSurfaceVariant),
            )
          else
            ...members.map((member) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.surfaceContainerHighest,
                      child: Icon(Icons.person_rounded, color: AppColors.outline),
                    ),
                    title: Text(
                      member['barberName'] as String? ?? '',
                      style: AppTypography.titleMedium.copyWith(color: AppColors.onSurface),
                    ),
                    subtitle: Text(
                      member['role'] == 'owner' ? 'Dueño' : 'Barbero',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      final barberId = member['barberId'] as String? ?? '';
                      if (barberId.isNotEmpty) {
                        context.go('/barberia/${member['barberId']}/barbero/$barberId');
                      }
                    },
                  ),
                )),
        ],
      ),
    );
  }
}
