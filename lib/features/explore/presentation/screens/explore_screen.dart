// lib/features/explore/presentation/screens/explore_screen.dart
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:barberly/shared/motion/app_motion.dart';
import 'package:barberly/shared/theme/app_theme.dart';
import 'package:barberly/features/explore/presentation/bloc/explore_bloc.dart';
import 'package:barberly/features/explore/presentation/extensions/service_explore_extensions.dart';

import '../widget/explore_header.dart';
import '../widget/explore_search_bar.dart';
import '../widget/promo_banner.dart';
import '../widget/category_chips.dart';
import '../widget/services_grid.dart';

// Categorías disponibles en la UI de Explorar
const kCategories = ['Todos', 'Corte', 'Barba', 'Combo', 'Tratamiento'];

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ExploreBloc>().add(const ExploreInitialized());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
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
    // FIX 1: mapear List<ServiceExploreEntity> → List<ServiceModel>
    // usando el extension method — cero lógica en el widget build.
    final serviceModels = state.services
        .map((e) => e.toServiceModel())
        .toList();

    // FIX 2: categoryFilter es String? — proveer fallback 'Todos'
    // para satisfacer los parámetros String (no-nullable) de CategoryChips
    // y ServicesGrid.
    final selectedCategory = state.categoryFilter ?? 'Todos';

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
                    child: ExploreHeader(
                      userName: state.userName,
                      onNotificationTap: () {},
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 2. Search bar
                  AppFadeSlideIn(
                    delay: AppMotion.delay(1),
                    child: ExploreSearchBar(
                      onChanged: (query) {
                        context.read<ExploreBloc>().add(
                          ExploreSearchQueryChanged(query),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 3. Promo banner
                  const AppFadeSlideIn(
                    delay: Duration(milliseconds: 140),
                    child: PromoBanner(),
                  ),
                  const SizedBox(height: 24),
                  // 4. Category chips
                  AppFadeSlideIn(
                    delay: AppMotion.delay(3),
                    child: CategoryChips(
                      categories: kCategories,
                      selectedCategory: selectedCategory, // String ✓
                      onSelected: (cat) {
                        // 'Todos' se normaliza a null para que el BLoC
                        // elimine el filtro y devuelva todos los servicios.
                        context.read<ExploreBloc>().add(
                          ExploreCategoryFilterChanged(
                            cat == 'Todos' ? null : cat.toLowerCase(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        // 5. Services grid
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          sliver: SliverToBoxAdapter(
            child: AppFadeSlideIn(
              delay: AppMotion.delay(4),
              child: ServicesGrid(
                services: serviceModels, // List<ServiceModel> ✓
                selectedCategory: selectedCategory, // String ✓
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Loading State ────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primaryContainer,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 16),
            Text(
              'Algo salió mal',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimary,
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
                  color: AppColors.onPrimary,
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
