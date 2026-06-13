import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/theme/app_theme.dart';
import '../../domain/entities/penalty.dart';
import '../cubit/penalties_cubit.dart';

class PenaltiesScreen extends StatelessWidget {
  const PenaltiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Penalizaciones',
          style: AppTypography.titleLarge.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<PenaltiesCubit, PenaltiesState>(
          builder: (context, state) => switch (state) {
            PenaltiesLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            PenaltiesEmpty() => const _EmptyState(),
            PenaltiesError(:final message) => _ErrorState(message: message),
            PenaltiesLoaded(:final penalties) => _PenaltiesList(
              penalties: penalties,
            ),
          },
        ),
      ),
    );
  }
}

class _PenaltiesList extends StatelessWidget {
  const _PenaltiesList({required this.penalties});

  final List<Penalty> penalties;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      itemCount: penalties.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _PenaltyCard(penalty: penalties[index]),
    );
  }
}

class _PenaltyCard extends StatelessWidget {
  const _PenaltyCard({required this.penalty});

  final Penalty penalty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _statusColor(colorScheme, penalty.status);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: statusColor.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ClientAvatar(imageUrl: penalty.clientAvatarUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          penalty.clientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.titleMedium.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          penalty.serviceName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _currency(penalty.penaltyAmount),
                      style: AppTypography.titleMedium.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _PenaltyChip(
                    label: _statusLabel(penalty.status),
                    color: statusColor,
                  ),
                  _PenaltyChip(
                    label: 'Cancelación tardía',
                    color: colorScheme.error,
                  ),
                  if (penalty.resolvedAt != null)
                    _PenaltyChip(
                      label: 'Resuelta',
                      color: colorScheme.tertiary,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Canceló con menos de 1 hora. Penalización del ${penalty.penaltyPercent}% sobre ${_currency(penalty.servicePrice)}.',
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatDateTime(penalty.appointmentStart),
                style: AppTypography.labelSmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (penalty.createdAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Generada el ${_formatDateTime(penalty.createdAt!)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (penalty.resolvedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Resuelta el ${_formatDateTime(penalty.resolvedAt!)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (compact) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () =>
                        context.read<PenaltiesCubit>().markAsPaid(penalty),
                    child: const Text('Marcar pagada'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () =>
                        context.read<PenaltiesCubit>().waive(penalty),
                    child: const Text('Perdonar'),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            context.read<PenaltiesCubit>().markAsPaid(penalty),
                        child: const Text('Marcar pagada'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            context.read<PenaltiesCubit>().waive(penalty),
                        child: const Text('Perdonar'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ClientAvatar extends StatelessWidget {
  const _ClientAvatar({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedUrl = imageUrl?.trim() ?? '';
    return CircleAvatar(
      radius: 24,
      backgroundColor: colorScheme.primaryContainer,
      backgroundImage: normalizedUrl.isEmpty
          ? null
          : NetworkImage(normalizedUrl),
      child: normalizedUrl.isEmpty
          ? Icon(Icons.person_rounded, color: colorScheme.onPrimaryContainer)
          : null,
    );
  }
}

class _PenaltyChip extends StatelessWidget {
  const _PenaltyChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No hay penalizaciones pendientes.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

String _currency(double value) => '₡${value.toStringAsFixed(0)}';

String _statusLabel(PenaltyStatus status) {
  return switch (status) {
    PenaltyStatus.pending => 'Pendiente',
    PenaltyStatus.paid => 'Pagada',
    PenaltyStatus.waived => 'Perdonada',
  };
}

Color _statusColor(ColorScheme colorScheme, PenaltyStatus status) {
  return switch (status) {
    PenaltyStatus.pending => colorScheme.error,
    PenaltyStatus.paid => colorScheme.primary,
    PenaltyStatus.waived => colorScheme.tertiary,
  };
}

String _formatDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '$day/$month/${date.year} · $hour:$minute $period';
}
