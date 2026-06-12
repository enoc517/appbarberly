import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/motion/app_motion.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../bloc/favorites_cubit.dart';
import '../../domain/entities/favorite_barbershop_entry.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<FavoritesCubit, FavoritesState>(
          builder: (context, state) => switch (state) {
            FavoritesLoading() => const _LoadingView(),
            FavoritesEmpty() => const _EmptyView(),
            FavoritesError(:final message) => _ErrorView(message: message),
            FavoritesLoaded(:final barbershops) => _LoadedView(
              barbershops: barbershops,
            ),
          },
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.barbershops});

  final List<FavoriteBarbershopEntry> barbershops;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        const AppFadeSlideIn(child: _Header()),
        const SizedBox(height: 20),
        for (final shop in barbershops) ...[
          _FavoriteBarbershopCard(shop: shop),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Favoritos', style: AppTypography.headlineLarge),
        const SizedBox(height: 6),
        Text(
          'Tus barberías guardadas para reservar más rápido.',
          style: AppTypography.bodyMedium.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _FavoriteBarbershopCard extends StatelessWidget {
  const _FavoriteBarbershopCard({required this.shop});

  final FavoriteBarbershopEntry shop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Icon(
              Icons.storefront_rounded,
              color: theme.colorScheme.onPrimaryContainer,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shop.shop.name, style: AppTypography.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '${shop.shop.rating.toStringAsFixed(1)} · ${shop.shop.reviewCount} reseñas · ${shop.bookingCount} reservas',
                  style: AppTypography.bodySmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  shop.shop.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusBadge(
                      label: shop.isOpenNow == true
                          ? 'Abierto ahora'
                          : shop.isOpenNow == false
                              ? 'Cerrado ahora'
                              : 'Horario no disponible',
                      color: shop.isOpenNow == true
                          ? theme.colorScheme.secondaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: shop.isOpenNow == true
                          ? theme.colorScheme.onSecondaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                      icon: shop.isOpenNow == true
                          ? Icons.storefront_rounded
                          : Icons.access_time_rounded,
                    ),
                    _StatusBadge(
                      label: shop.lastServiceName?.isNotEmpty == true
                          ? 'Último: ${shop.lastServiceName}'
                          : 'Sin uso reciente',
                      color: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      icon: Icons.history_rounded,
                    ),
                    if (shop.nextAvailableLabel != null)
                      _StatusBadge(
                        label: shop.nextAvailableLabel!,
                        color: theme.colorScheme.surfaceContainerHighest,
                        foregroundColor: theme.colorScheme.onSurfaceVariant,
                        icon: Icons.event_available_rounded,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(Icons.favorite_rounded, color: theme.colorScheme.secondary),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: shop.lastBarberId == null || shop.lastBarberId!.isEmpty
                    ? null
                    : () => context.push(
                          '/barberia/${shop.shop.id}/barbero/${shop.lastBarberId}',
                        ),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                ),
                child: const Text('Reservar de nuevo'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.push('/barberia/${shop.shop.id}'),
                child: const Text('Ver barbería'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.foregroundColor,
    required this.icon,
  });

  final String label;
  final Color color;
  final Color foregroundColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Todavía no tienes favoritos.'));
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}
