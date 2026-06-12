import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_theme.dart';
import '../cubit/barbershop_reviews_cubit.dart';
import '../cubit/barbershop_reviews_state.dart';
import '../widgets/review_card.dart';

class BarbershopReviewsScreen extends StatefulWidget {
  const BarbershopReviewsScreen({super.key, required this.shopName});

  final String shopName;

  @override
  State<BarbershopReviewsScreen> createState() => _BarbershopReviewsScreenState();
}

class _BarbershopReviewsScreenState extends State<BarbershopReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BarbershopReviewsCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Reseñas de ${widget.shopName}')),
      body: BlocBuilder<BarbershopReviewsCubit, BarbershopReviewsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null && state.reviews.isEmpty) {
            return Center(child: Text(state.errorMessage!));
          }
          if (state.reviews.isEmpty) {
            return Center(
              child: Text(
                'Todavía no hay reseñas.',
                style: AppTypography.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _SortChip(
                        label: 'Recientes',
                        selected: state.sortMode == ReviewSortMode.recent,
                        onSelected: () => context
                            .read<BarbershopReviewsCubit>()
                            .setSortMode(ReviewSortMode.recent),
                      ),
                      _SortChip(
                        label: 'Mejor valoradas',
                        selected: state.sortMode == ReviewSortMode.highestRated,
                        onSelected: () => context
                            .read<BarbershopReviewsCubit>()
                            .setSortMode(ReviewSortMode.highestRated),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 200) {
                      context.read<BarbershopReviewsCubit>().loadMore();
                    }
                    return false;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    itemCount:
                        state.reviews.length + (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (context, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index >= state.reviews.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return ReviewCard(review: state.reviews[index]);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: AppTypography.labelLarge.copyWith(
        color: selected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(
        color: selected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.outlineVariant,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
    );
  }
}
