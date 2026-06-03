import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/motion/app_motion.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../cubit/barber_booking_cubit.dart';
import '../cubit/barber_booking_state.dart';

class BarberBookingScreen extends StatelessWidget {
  const BarberBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _BarberBookingView();
  }
}

class _BarberBookingView extends StatelessWidget {
  const _BarberBookingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<BarberBookingCubit, BarberBookingState>(
      listenWhen: (prev, curr) =>
          prev.isBooking != curr.isBooking ||
          prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppToast.error(context, 'Error: ${state.errorMessage}');
        }
        if (!state.isBooking &&
            state.errorMessage == null &&
            state.canConfirm) {
          AppToast.success(context, 'Reserva confirmada');
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/explorar'),
          ),
          title: BlocBuilder<BarberBookingCubit, BarberBookingState>(
            builder: (context, state) => Text(
              state.barberName ?? 'Barbero',
              style: AppTypography.titleLarge.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        body: BlocBuilder<BarberBookingCubit, BarberBookingState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return const _BookingContent();
          },
        ),
        bottomNavigationBar:
            BlocBuilder<BarberBookingCubit, BarberBookingState>(
              buildWhen: (prev, curr) =>
                  prev.canConfirm != curr.canConfirm ||
                  prev.isBooking != curr.isBooking,
              builder: (context, state) {
                return SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: state.canConfirm
                            ? () => context
                                  .read<BarberBookingCubit>()
                                  .confirmBooking()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          foregroundColor: theme.colorScheme.onPrimaryContainer,
                          disabledBackgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          disabledForegroundColor:
                              theme.colorScheme.onSurfaceVariant,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                          elevation: 0,
                        ),
                        child: state.isBooking
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              )
                            : const Text(
                                'Confirmar reserva',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}

class _BookingContent extends StatelessWidget {
  const _BookingContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<BarberBookingCubit, BarberBookingState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).padding.bottom + 180,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppFadeSlideIn(
                child: Text(
                  'Servicios',
                  style: AppTypography.titleLarge.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (state.services.isEmpty)
                Text(
                  'No hay servicios disponibles',
                  style: AppTypography.bodyLarge.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                ...state.services.map((svc) => _ServiceTile(service: svc)),
              const SizedBox(height: 24),
              if (state.selectedService != null) ...[
                AppFadeSlideIn(
                  child: Text(
                    'Selecciona el día',
                    style: AppTypography.titleLarge.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (state.availableDays.isEmpty)
                  Text(
                    'No hay días disponibles',
                    style: AppTypography.bodyLarge.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (
                          var i = 0;
                          i < state.availableDays.length;
                          i++
                        ) ...[
                          _DayChip(
                            day: state.availableDays[i],
                            selected:
                                state.selectedDay == state.availableDays[i],
                            onTap: () => context
                                .read<BarberBookingCubit>()
                                .selectDay(state.availableDays[i]),
                          ),
                          if (i != state.availableDays.length - 1)
                            const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              if (state.selectedService != null &&
                  state.selectedDay != null) ...[
                AppFadeSlideIn(
                  child: Text(
                    'Selecciona la hora',
                    style: AppTypography.titleLarge.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (state.isLoadingSlots)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.availableTimes.isEmpty)
                  Text(
                    'No hay horarios disponibles para este día.',
                    style: AppTypography.bodyLarge.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.availableTimes.map((time) {
                      final selected = state.selectedTime == time;
                      return _TimeSlotButton(
                        time: time,
                        selected: selected,
                        onTap: () =>
                            context.read<BarberBookingCubit>().selectTime(time),
                      );
                    }).toList(),
                  ),
              ],
              if (state.selectedService == null) ...[
                const SizedBox(height: 8),
                Text(
                  'Selecciona un servicio para ver horarios disponibles.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _TimeSlotButton extends StatelessWidget {
  const _TimeSlotButton({
    required this.time,
    required this.selected,
    required this.onTap,
  });

  final String time;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = selected
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final foregroundColor = selected
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      label: selected
          ? 'Horario $time seleccionado'
          : 'Seleccionar horario $time',
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.full),
          onTap: onTap,
          splashColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          highlightColor: theme.colorScheme.primary.withValues(alpha: 0.08),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 92, minHeight: 48),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.outlineVariant,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selected) ...[
                    Icon(Icons.check_rounded, size: 18, color: foregroundColor),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    time,
                    style: AppTypography.labelLarge.copyWith(
                      color: foregroundColor,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _weekdayLabel(day.weekday),
                style: AppTypography.labelSmall.copyWith(
                  color: selected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${day.day}/${day.month}',
                style: AppTypography.titleSmall.copyWith(
                  color: selected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _weekdayLabel(int weekday) => switch (weekday) {
    1 => 'Lun',
    2 => 'Mar',
    3 => 'Mié',
    4 => 'Jue',
    5 => 'Vie',
    6 => 'Sáb',
    7 => 'Dom',
    _ => '',
  };
}

class _ServiceTile extends StatelessWidget {
  final Map<String, dynamic> service;
  const _ServiceTile({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<BarberBookingCubit, BarberBookingState>(
      buildWhen: (prev, curr) => prev.selectedService != curr.selectedService,
      builder: (context, state) {
        final selected = state.selectedService?['id'] == service['id'];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: selected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              onTap: () =>
                  context.read<BarberBookingCubit>().selectService(service),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: selected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.colorScheme.onPrimaryContainer.withValues(
                                alpha: 0.12,
                              )
                            : theme.colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Icon(
                        Icons.cut_rounded,
                        color: selected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  service['name'] as String,
                                  style: AppTypography.titleMedium.copyWith(
                                    color: selected
                                        ? theme.colorScheme.onPrimaryContainer
                                        : theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (selected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: theme.colorScheme.onPrimaryContainer,
                                  size: 20,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₡${(service['price'] as num).toStringAsFixed(0)} · ${service['durationMinutes']} min',
                            style: AppTypography.bodySmall.copyWith(
                              color: selected
                                  ? theme.colorScheme.onPrimaryContainer
                                        .withValues(alpha: 0.82)
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            service['description'] as String? ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: selected
                                  ? theme.colorScheme.onPrimaryContainer
                                        .withValues(alpha: 0.82)
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
