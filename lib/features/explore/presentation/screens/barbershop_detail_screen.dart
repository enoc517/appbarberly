import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/motion/app_motion.dart';
import '../../../reviews/domain/entities/barbershop_review.dart';
import '../cubit/barbershop_detail_cubit.dart';
import '../cubit/barbershop_detail_state.dart';

class BarbershopDetailScreen extends StatelessWidget {
  const BarbershopDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _BarbershopDetailView();
  }
}

class _BarbershopDetailView extends StatelessWidget {
  const _BarbershopDetailView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/explorar'),
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
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          final shopId = context.read<BarbershopDetailCubit>().shopId;
          return _DetailContent(
            shopId: shopId,
            shop: state.shop!,
            members: state.members,
            reviews: state.reviews,
          );
        },
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final String shopId;
  final Map<String, dynamic> shop;
  final List<Map<String, dynamic>> members;
  final List<BarbershopReview> reviews;

  const _DetailContent({
    required this.shopId,
    required this.shop,
    required this.members,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                color: theme.colorScheme.surfaceContainerHighest,
                child: (shop['imageUrl'] as String?)?.isNotEmpty == true
                    ? Image.network(shop['imageUrl']!, fit: BoxFit.cover)
                    : Icon(Icons.storefront_rounded, size: 64, color: theme.colorScheme.outline),
              ),
            ),
          ),
          const SizedBox(height: 20),
          AppFadeSlideIn(
            delay: AppMotion.delay(1),
            child: Text(
              shop['name'] as String? ?? '',
              style: AppTypography.headlineMedium.copyWith(color: theme.colorScheme.onSurface),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.star_rounded, size: 18, color: theme.colorScheme.secondary),
              const SizedBox(width: 4),
              Text(
                '${shop['rating'] ?? 0} (${shop['reviewCount'] ?? 0} reseñas)',
                style: AppTypography.bodyMedium.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  shop['address'] as String? ?? '',
                  style: AppTypography.bodyMedium.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                              style: AppTypography.labelSmall.copyWith(color: theme.colorScheme.onPrimaryContainer)),
                          backgroundColor: theme.colorScheme.primaryContainer,
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
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          if (members.isEmpty)
            Text(
              'No hay barberos aún',
              style: AppTypography.bodyLarge.copyWith(color: theme.colorScheme.onSurfaceVariant),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final crossAxisCount = width < 360 ? 1 : 2;
                final isCompact = width < 390;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: isCompact ? 250 : 270,
                  ),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return _BarberMemberCard(
                      member: member,
                      onTap: () {
                        final barberId = member['barberId'] as String? ?? '';
                        if (barberId.isNotEmpty) {
                          context.go('/barberia/$shopId/barbero/$barberId');
                        }
                      },
                    );
                  },
                );
              },
            ),
          const SizedBox(height: 28),
          Text(
            'Reseñas recientes',
            style: AppTypography.titleLarge.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.push(
              '/barberia/$shopId/resenas',
              extra: shop['name'] as String? ?? 'Barbería',
            ),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
            ),
            child: const Text('Ver todas las reseñas'),
          ),
          const SizedBox(height: 16),
          if (reviews.isEmpty)
            Text(
              'Todavía no hay reseñas para esta barbería.',
              style: AppTypography.bodyMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final review in reviews)
              _ReviewCard(review: review),
        ],
      ),
    );
  }
}

class _BarberMemberCard extends StatelessWidget {
  const _BarberMemberCard({required this.member, required this.onTap});

  final Map<String, dynamic> member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = member['barberName'] as String? ?? 'Barbero';
    final roleLabel = member['role'] == 'owner' ? 'Dueño' : 'Barbero';
    final avatarUrl = member['barberAvatarUrl'] as String? ?? '';

    return Semantics(
      button: true,
      label: 'Reservar con $name, $roleLabel',
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: _BarberAvatar(name: name, imageUrl: avatarUrl),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleMedium.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(
                              AppRadius.full,
                            ),
                          ),
                          child: Text(
                            roleLabel,
                            style: AppTypography.labelSmall.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              'Reservar',
                              style: AppTypography.labelMedium.copyWith(
                                color: colorScheme.secondary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: colorScheme.secondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarberAvatar extends StatelessWidget {
  const _BarberAvatar({required this.name, required this.imageUrl});

  final String name;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: imageUrl.isEmpty
          ? _AvatarFallback(name: name)
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              semanticLabel: 'Foto de $name',
              errorBuilder: (context, error, stackTrace) =>
                  _AvatarFallback(name: name),
            ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final BarbershopReview review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clientName = review.clientSnapshot.name;
    final serviceName = review.serviceSnapshot.name;
    final rating = review.rating;
    final comment = review.comment ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  clientName,
                  style: AppTypography.titleSmall,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            serviceName,
            style: AppTypography.labelSmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (comment.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment.trim(),
              style: AppTypography.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final initial = name.trim().isEmpty ? 'B' : name.trim()[0].toUpperCase();

    return Center(
      child: Text(
        initial,
        style: AppTypography.headlineSmall.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
