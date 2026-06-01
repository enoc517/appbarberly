import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/motion/app_motion.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../../../../bookings/domain/entities/booking.dart';
import '../bloc/barber_agenda_cubit.dart';

class BarberAgendaScreen extends StatelessWidget {
  const BarberAgendaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<BarberAgendaCubit, BarberAgendaState>(
          builder: (context, state) => switch (state) {
            BarberAgendaLoading() => const _LoadingView(),
            BarberAgendaEmpty(:final message) => _EmptyView(message: message),
            BarberAgendaError(:final message) => _ErrorView(message: message),
            BarberAgendaLoaded(:final bookings, :final selectedDay) =>
              _LoadedView(bookings: bookings, selectedDay: selectedDay),
          },
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.bookings, required this.selectedDay});

  final List<Booking> bookings;
  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        const AppFadeSlideIn(child: _Header()),
        const SizedBox(height: 18),
        AppFadeSlideIn(
          delay: AppMotion.delay(1),
          child: _DayStrip(selectedDay: selectedDay),
        ),
        const SizedBox(height: 22),
        if (bookings.isEmpty)
          const _InlineEmpty(message: 'No hay citas para este día.')
        else
          for (final booking in bookings) _AgendaBlock(booking: booking),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Agenda', style: AppTypography.headlineLarge),
              const SizedBox(height: 6),
              Text(
                'Vista operativa de citas y espacios disponibles.',
                style: AppTypography.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.selectedDay});

  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) {
    final start = selectedDay.subtract(Duration(days: selectedDay.weekday - 1));
    final days = List.generate(5, (index) => start.add(Duration(days: index)));
    return Row(
      children: [
        for (var i = 0; i < days.length; i++) ...[
          Expanded(
            child: _DayPill(
              date: days[i],
              selected: _sameDay(days[i], selectedDay),
              onTap: () => context.read<BarberAgendaCubit>().selectDay(days[i]),
            ),
          ),
          if (i != days.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          children: [
            Text(
              labels[date.weekday - 1],
              style: AppTypography.labelSmall.copyWith(
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date.day.toString().padLeft(2, '0'),
              style: AppTypography.titleSmall.copyWith(
                color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaBlock extends StatelessWidget {
  const _AgendaBlock({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 54,
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                _formatTime(booking.slotStart),
                style: AppTypography.labelLarge,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.clientSnapshot.name,
                          style: AppTypography.titleSmall,
                        ),
                        Text(
                          booking.serviceSnapshot.name,
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        booking.status.label,
                        style: AppTypography.labelSmall.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (booking.isActive) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context
                              .read<BarberAgendaCubit>()
                              .completeBooking(booking),
                          child: const Text('Completar'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      message,
      style: AppTypography.bodyMedium.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
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
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNoBarbershop = message.contains('barbería');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isNoBarbershop
                  ? Icons.storefront_rounded
                  : Icons.calendar_today_outlined,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            Text(
              isNoBarbershop ? 'Sin barbería asignada' : 'Sin citas',
              style: AppTypography.titleLarge.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
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
            if (isNoBarbershop) ...[
              const SizedBox(height: 32),
              AppFadeSlideIn(
                delay: AppMotion.delay(1),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.go('/barberia'),
                    icon: const Icon(Icons.storefront_rounded),
                    label: const Text('Ir a Barbería'),
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

String _formatTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
