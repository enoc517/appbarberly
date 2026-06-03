// lib/features/explore/presentation/screens/explore_screen.dart
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:barberly/shared/motion/app_motion.dart';
import 'package:barberly/shared/theme/app_theme.dart';
import 'package:barberly/features/explore/domain/entities/explore_entities.dart';
import 'package:barberly/features/explore/presentation/bloc/explore_bloc.dart';
import 'package:barberly/features/notifications/presentation/cubit/notifications_cubit.dart';

import '../widget/explore_header.dart';
import '../widget/explore_search_bar.dart';

const kExploreRadii = [5.0, 10.0, 25.0, 50.0];

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ExploreBloc>().add(const ExploreInitialized());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      extendBody: true,
      body: BlocBuilder<ExploreBloc, ExploreState>(
        builder: (context, state) {
          return switch (state) {
            ExploreLoading() => const _LoadingView(),
            ExploreLoaded() => _LoadedView(state: state),
            ExploreFavoritesEmpty() => const _LoadingView(),
            ExploreError(:final message) => _ErrorView(message: message),
            _ => const SizedBox.shrink(),
          };
        },
      ),
      // El BottomNavigationBar lo provee MainShell (StatefulShellRoute en
      // app_router.dart). No declarar uno aquí: causaría doble bottom nav
      // y bugs como AssertionError 'items.length >= 2' cuando los items
      // vienen vacíos.
    );
  }
}

// ─── Loaded State ────────────────────────────────────────────────────────────

class _LoadedView extends StatelessWidget {
  final ExploreLoaded state;
  const _LoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header
                  AppFadeSlideIn(
                    child: BlocBuilder<NotificationsCubit, NotificationsState>(
                      builder: (context, notificationState) => ExploreHeader(
                        userName: state.userName,
                        unreadNotifications: notificationState.unreadCount,
                        onNotificationTap: () =>
                            context.push('/notificaciones'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 2. Search bar
                  AppFadeSlideIn(
                    delay: AppMotion.delay(1),
                    child: ExploreSearchBar(
                      hint: 'Buscar barbería, barbero o servicio...',
                      onChanged: (query) {
                        context.read<ExploreBloc>().add(
                          ExploreSearchQueryChanged(query),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppFadeSlideIn(
                    delay: AppMotion.delay(2),
                    child: _DistanceFilter(radiusKm: state.radiusKm),
                  ),
                  const SizedBox(height: 24),
                  AppFadeSlideIn(
                    delay: AppMotion.delay(3),
                    child: _BarbershopsSection(barbershops: state.barbershops),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DistanceFilter extends StatelessWidget {
  const _DistanceFilter({required this.radiusKm});

  final double radiusKm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distancia',
          style: AppTypography.labelLarge.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final radius in kExploreRadii) ...[
                _RadiusChip(radiusKm: radius, selected: radiusKm == radius),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RadiusChip extends StatelessWidget {
  const _RadiusChip({required this.radiusKm, required this.selected});

  final double radiusKm;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text('${radiusKm.toInt()} km'),
      selected: selected,
      onSelected: (_) {
        context.read<ExploreBloc>().add(ExploreRadiusChanged(radiusKm));
      },
      labelStyle: AppTypography.labelMedium.copyWith(
        color: selected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: theme.colorScheme.primaryContainer,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
    );
  }
}

class _BarbershopsSection extends StatelessWidget {
  const _BarbershopsSection({required this.barbershops});

  final List<BarbershopEntity> barbershops;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Barberías cercanas',
              style: AppTypography.headlineSmall.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              '${barbershops.length} resultados',
              style: AppTypography.labelMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (barbershops.isEmpty)
          const _BarbershopsEmptyState()
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
                  mainAxisExtent: isCompact ? 280 : 300,
                ),
                itemCount: barbershops.length,
                itemBuilder: (context, index) {
                  return _BarbershopCard(shop: barbershops[index]);
                },
              );
            },
          ),
      ],
    );
  }
}

class _BarbershopCard extends StatelessWidget {
  const _BarbershopCard({required this.shop});

  final BarbershopEntity shop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppPressable(
      onTap: () => context.push('/barberia/${shop.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero image
            Stack(
              children: [
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: shop.imageUrl.isEmpty
                      ? Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.storefront_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 48,
                          ),
                        )
                      : Image.network(
                          shop.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.storefront_rounded,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 48,
                                ),
                              ),
                        ),
                ),
                if (shop.hasActivePromotion)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.secondary,
                            theme.colorScheme.tertiary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.secondary.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 14,
                            color: theme.colorScheme.onSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'OFERTA',
                            style: AppTypography.labelSmall.copyWith(
                              color: theme.colorScheme.onSecondary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            // Info section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shop.barberNames.isNotEmpty
                          ? shop.barberNames.join(', ')
                          : shop.ownerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: theme.colorScheme.tertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          shop.rating.toStringAsFixed(1),
                          style: AppTypography.labelMedium.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          ' (${shop.reviewCount})',
                          style: AppTypography.labelSmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          shop.distanceKm == null
                              ? ''
                              : '${shop.distanceKm!.toStringAsFixed(1)} km',
                          style: AppTypography.labelSmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
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
    );
  }
}

class _BarbershopsEmptyState extends StatelessWidget {
  const _BarbershopsEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Text(
        'No encontramos barberías en este radio. Probá ampliar la distancia.',
        textAlign: TextAlign.center,
        style: AppTypography.bodyMedium.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ─── Loading State ────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: CircularProgressIndicator(
        color: theme.colorScheme.primaryContainer,
        strokeWidth: 2.5,
      ),
    );
  }
}

// ─── Error State ─────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 16),
            Text(
              'Algo salió mal',
              style: AppTypography.headlineSmall.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
              ),
              onPressed: () {
                context.read<ExploreBloc>().add(const ExploreInitialized());
              },
              child: Text(
                'Reintentar',
                style: AppTypography.labelMedium.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
