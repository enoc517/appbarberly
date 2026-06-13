import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/motion/app_motion.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../../../../bookings/domain/entities/booking.dart';
import '../bloc/barber_agenda_cubit.dart';

enum _AgendaFilter { all, pending, completed, cancelled }

class BarberAgendaScreen extends StatefulWidget {
  const BarberAgendaScreen({super.key});

  @override
  State<BarberAgendaScreen> createState() => _BarberAgendaScreenState();
}

class _BarberAgendaScreenState extends State<BarberAgendaScreen> {
  _AgendaFilter _filter = _AgendaFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<BarberAgendaCubit, BarberAgendaState>(
          builder: (context, state) {
            if (state is BarberAgendaLoading) {
              return const _LoadingView();
            }
            if (state is BarberAgendaEmpty) {
              return _EmptyView(message: state.message);
            }
            if (state is BarberAgendaError) {
              return _ErrorView(message: state.message);
            }
            if (state is BarberAgendaLoaded) {
              return _LoadedView(
                state: state,
                isLoadingBookings: state.isLoadingBookings,
                filter: _filter,
                onFilterChanged: (value) {
                  setState(() => _filter = value);
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.state,
    required this.isLoadingBookings,
    required this.filter,
    required this.onFilterChanged,
  });

  final BarberAgendaLoaded state;
  final bool isLoadingBookings;
  final _AgendaFilter filter;
  final ValueChanged<_AgendaFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final bookings = state.bookings;
    final selectedDay = state.selectedDay;
    final visibleDays = state.visibleDays;
    final filteredBookings = _filterBookings(bookings, filter);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        const AppFadeSlideIn(child: _Header()),
        const SizedBox(height: 18),
        _WeekNavigator(selectedDay: selectedDay),
        const SizedBox(height: 12),
        AppFadeSlideIn(
          delay: AppMotion.delay(1),
          child: _DayStrip(selectedDay: selectedDay, days: visibleDays),
        ),
        const SizedBox(height: 22),
        _AgendaSummary(
          total: state.totalBookings,
          pending: state.activeBookings.length,
          completed: state.completedCount,
          cancelled: state.cancelledCount,
          income: state.dayIncome,
        ),
        const SizedBox(height: 16),
        _AgendaFilterChips(selected: filter, onChanged: onFilterChanged),
        const SizedBox(height: 18),
        _BlockedSlotsSection(
          blockedSlots: state.blockedSlots,
          onBlockSpace: () => _blockSpace(context, state.selectedDay),
          onCancelSlot: (slot) => _cancelBlockedSlot(context, slot),
        ),
        const SizedBox(height: 18),
        if (isLoadingBookings)
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (filteredBookings.isEmpty)
          _InlineEmpty(message: _emptyMessageFor(filter))
        else
          for (final booking in filteredBookings)
            _AgendaBlock(booking: booking),
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

class _WeekNavigator extends StatelessWidget {
  const _WeekNavigator({required this.selectedDay});

  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = _weekLabel(selectedDay);
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: () => context.read<BarberAgendaCubit>().previousWeek(),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Usá las flechas para ver semanas anteriores o futuras',
                textAlign: TextAlign.center,
                style: AppTypography.labelSmall.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.tonal(
          onPressed: () => context.read<BarberAgendaCubit>().goToCurrentWeek(),
          child: const Text('Hoy'),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: () => context.read<BarberAgendaCubit>().nextWeek(),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.selectedDay, required this.days});

  final DateTime selectedDay;
  final List<DateTime> days;
  static const double _minPillWidth = 56;
  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalGap = _gap * (days.length - 1);
        final rawItemWidth = (constraints.maxWidth - totalGap) / days.length;
        final fits = rawItemWidth >= _minPillWidth;
        final itemWidth = fits ? rawItemWidth : _minPillWidth;
        final pillWidth = fits ? itemWidth : _minPillWidth;

        final strip = Row(
          children: [
            for (var i = 0; i < days.length; i++) ...[
              _DayPill(
                width: pillWidth,
                date: days[i],
                selected: _sameDay(days[i], selectedDay),
                onTap: () =>
                    context.read<BarberAgendaCubit>().selectDay(days[i]),
              ),
              if (i != days.length - 1) const SizedBox(width: _gap),
            ],
          ],
        );

        if (fits) {
          return strip;
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: strip,
        );
      },
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.width,
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final double width;
  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    return Material(
      color: selected
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
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
                    color: selected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
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

class _AgendaBlock extends StatelessWidget {
  const _AgendaBlock({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final agendaCubit = context.read<BarberAgendaCubit>();
    final canComplete = agendaCubit.canCompleteBooking(booking);
    final cancelledBy = switch (booking.cancelledBy) {
      BookingCancellationActor.barber => 'Cancelada por vos',
      BookingCancellationActor.client => 'Cancelada por el cliente',
      null => null,
    };
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
                        const SizedBox(height: 4),
                        Text(
                          '${_formatTimeRange(booking.slotStart, booking.slotEnd)} · ${booking.durationMinutes} min · ₡${booking.price.toStringAsFixed(0)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if ((booking.cancellationReason ?? '')
                            .trim()
                            .isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Motivo: ${booking.cancellationReason!.trim()}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _statusStyle(
                            booking.status,
                            theme.colorScheme,
                          ).background,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          booking.status.label,
                          style: AppTypography.labelSmall.copyWith(
                            color: _statusStyle(
                              booking.status,
                              theme.colorScheme,
                            ).foreground,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (cancelledBy != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          cancelledBy,
                          style: AppTypography.labelSmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (booking.isActive) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: [
                            FilledButton.icon(
                              onPressed: canComplete
                                  ? () => _completeBooking(context, booking)
                                  : null,
                              icon: const Icon(
                                Icons.check_circle_outline_rounded,
                              ),
                              label: const Text('Completar'),
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                foregroundColor:
                                    theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _cancelBooking(context, booking),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                                side: BorderSide(
                                  color: theme.colorScheme.error.withValues(
                                    alpha: 0.55,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.cancel_rounded),
                              label: const Text('Cancelar'),
                            ),
                          ],
                        ),
                        if (!canComplete) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Disponible al finalizar la cita',
                            style: AppTypography.labelSmall.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
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

class _AgendaSummary extends StatelessWidget {
  const _AgendaSummary({
    required this.total,
    required this.pending,
    required this.completed,
    required this.cancelled,
    required this.income,
  });

  final int total;
  final int pending;
  final int completed;
  final int cancelled;
  final double income;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _AgendaStatCard(
          label: 'Total',
          value: total.toString(),
          icon: Icons.today_rounded,
          color: theme.colorScheme.primary,
        ),
        _AgendaStatCard(
          label: 'Pendientes',
          value: pending.toString(),
          icon: Icons.event_available_rounded,
          color: theme.colorScheme.primary,
        ),
        _AgendaStatCard(
          label: 'Completadas',
          value: completed.toString(),
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF2E7D32),
        ),
        _AgendaStatCard(
          label: 'Canceladas',
          value: cancelled.toString(),
          icon: Icons.event_busy_rounded,
          color: theme.colorScheme.error,
        ),
        _AgendaStatCard(
          label: 'Ingreso',
          value: '₡${income.toStringAsFixed(0)}',
          icon: Icons.payments_rounded,
          color: theme.colorScheme.primary,
        ),
      ],
    );
  }
}

class _AgendaStatCard extends StatelessWidget {
  const _AgendaStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 130,
      padding: const EdgeInsets.all(14),
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedSlotsSection extends StatelessWidget {
  const _BlockedSlotsSection({
    required this.blockedSlots,
    required this.onBlockSpace,
    required this.onCancelSlot,
  });

  final List<AgendaBlockedSlot> blockedSlots;
  final VoidCallback onBlockSpace;
  final ValueChanged<AgendaBlockedSlot> onCancelSlot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Espacios bloqueados',
                style: AppTypography.titleLarge,
              ),
            ),
            TextButton.icon(
              onPressed: onBlockSpace,
              icon: const Icon(Icons.block_rounded),
              label: const Text('Bloquear'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (blockedSlots.isEmpty)
          Text(
            'No hay espacios bloqueados para este día.',
            style: AppTypography.bodyMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          for (final slot in blockedSlots) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.12,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.block_rounded, color: theme.colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_formatTime(slot.start)} - ${_formatTime(slot.end)}',
                          style: AppTypography.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          slot.reason,
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cancelar bloqueo',
                    onPressed: () => onCancelSlot(slot),
                    icon: Icon(
                      Icons.close_rounded,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
      ],
    );
  }
}

class _AgendaFilterChips extends StatelessWidget {
  const _AgendaFilterChips({required this.selected, required this.onChanged});

  final _AgendaFilter selected;
  final ValueChanged<_AgendaFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChip(
          label: 'Todas',
          selected: selected == _AgendaFilter.all,
          onTap: () => onChanged(_AgendaFilter.all),
        ),
        _FilterChip(
          label: 'Pendientes',
          selected: selected == _AgendaFilter.pending,
          onTap: () => onChanged(_AgendaFilter.pending),
        ),
        _FilterChip(
          label: 'Completadas',
          selected: selected == _AgendaFilter.completed,
          onTap: () => onChanged(_AgendaFilter.completed),
        ),
        _FilterChip(
          label: 'Canceladas',
          selected: selected == _AgendaFilter.cancelled,
          onTap: () => onChanged(_AgendaFilter.cancelled),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
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

List<Booking> _filterBookings(List<Booking> bookings, _AgendaFilter filter) {
  return switch (filter) {
    _AgendaFilter.all => bookings,
    _AgendaFilter.pending =>
      bookings.where((booking) => booking.isActive).toList(growable: false),
    _AgendaFilter.completed =>
      bookings
          .where(
            (booking) => booking.status == AppointmentBookingStatus.completed,
          )
          .toList(growable: false),
    _AgendaFilter.cancelled =>
      bookings
          .where(
            (booking) => booking.status == AppointmentBookingStatus.cancelled,
          )
          .toList(growable: false),
  };
}

String _emptyMessageFor(_AgendaFilter filter) {
  return switch (filter) {
    _AgendaFilter.all => 'No hay citas para este día.',
    _AgendaFilter.pending => 'No hay citas pendientes para este día.',
    _AgendaFilter.completed => 'No hay citas completadas para este día.',
    _AgendaFilter.cancelled => 'No hay citas canceladas para este día.',
  };
}

Future<void> _completeBooking(BuildContext context, Booking booking) async {
  final success = await context.read<BarberAgendaCubit>().completeBooking(
    booking,
  );
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        success ? 'Cita completada' : 'No se pudo completar la cita',
      ),
    ),
  );
}

Future<void> _cancelBooking(BuildContext context, Booking booking) async {
  final shouldCancel = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Cancelar cita'),
        content: Text(
          '¿Querés cancelar la cita de ${booking.clientSnapshot.name} para ${booking.serviceSnapshot.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      );
    },
  );

  if (shouldCancel != true || !context.mounted) return;

  final success = await context.read<BarberAgendaCubit>().cancelBooking(
    booking,
  );
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(success ? 'Cita cancelada' : 'No se pudo cancelar la cita'),
    ),
  );
}

Future<void> _blockSpace(BuildContext context, DateTime selectedDay) async {
  final result = await showDialog<_BlockSpaceDraft?>(
    context: context,
    builder: (dialogContext) {
      var startTime = '12:00';
      var endTime = '13:00';
      var reason = '';
      return StatefulBuilder(
        builder: (context, setState) {
          final canConfirm =
              reason.trim().length >= 5 &&
              _parseTimeOfDay(startTime) != null &&
              _parseTimeOfDay(endTime) != null;
          return AlertDialog(
            title: const Text('Bloquear espacio'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Este espacio quedará fuera de la agenda para ${_formatDate(selectedDay)}.',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: startTime,
                        decoration: const InputDecoration(
                          labelText: 'Inicio (HH:mm)',
                        ),
                        onChanged: (value) =>
                            setState(() => startTime = value.trim()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: endTime,
                        decoration: const InputDecoration(
                          labelText: 'Fin (HH:mm)',
                        ),
                        onChanged: (value) =>
                            setState(() => endTime = value.trim()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                    hintText: 'Ej: emergencia personal, almuerzo, diligencia',
                  ),
                  onChanged: (value) => setState(() => reason = value),
                ),
                const SizedBox(height: 8),
                Text(
                  'El bloqueo se mostrará en la agenda como un espacio no disponible.',
                  style: AppTypography.labelSmall.copyWith(
                    color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Volver'),
              ),
              FilledButton(
                onPressed: canConfirm
                    ? () => Navigator.of(dialogContext).pop(
                        _BlockSpaceDraft(
                          start: _mergeDateAndTime(selectedDay, startTime)!,
                          end: _mergeDateAndTime(selectedDay, endTime)!,
                          reason: reason.trim(),
                        ),
                      )
                    : null,
                child: const Text('Bloquear'),
              ),
            ],
          );
        },
      );
    },
  );

  if (result == null || !context.mounted) return;

  final currentState = context.read<BarberAgendaCubit>().state;
  if (currentState is BarberAgendaLoaded) {
    final hasOverlap = currentState.activeBookings.any(
      (booking) => _overlaps(
        result.start,
        result.end,
        booking.slotStart,
        booking.slotEnd,
      ),
    );
    if (hasOverlap) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tenés citas activas en ese horario. Reprogramalas o cancelalas primero.',
          ),
        ),
      );
      return;
    }

    final hasBlockedOverlap = currentState.blockedSlots.any(
      (slot) => _overlaps(result.start, result.end, slot.start, slot.end),
    );
    if (hasBlockedOverlap) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya había un bloqueo en ese horario.')),
      );
      return;
    }
  }

  final success = await context.read<BarberAgendaCubit>().blockSlot(
    start: result.start,
    end: result.end,
    reason: result.reason,
  );

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        success ? 'Espacio bloqueado' : 'No se pudo bloquear el espacio',
      ),
    ),
  );
}

Future<void> _cancelBlockedSlot(
  BuildContext context,
  AgendaBlockedSlot slot,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Cancelar bloqueo'),
        content: Text(
          '¿Querés liberar ${_formatTimeRange(slot.start, slot.end)}? El horario volverá a estar disponible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancelar bloqueo'),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) return;

  final success = await context.read<BarberAgendaCubit>().cancelBlockedSlot(
    slot.id,
  );

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        success ? 'Bloqueo cancelado' : 'No se pudo cancelar el bloqueo',
      ),
    ),
  );
}

DateTime? _mergeDateAndTime(DateTime day, String time) {
  final parsed = _parseTimeOfDay(time);
  if (parsed == null) return null;
  return DateTime(day.year, day.month, day.day, parsed.hour, parsed.minute);
}

bool _overlaps(DateTime aStart, DateTime aEnd, DateTime bStart, DateTime bEnd) {
  return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
}

TimeOfDay? _parseTimeOfDay(String value) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
  if (match == null) return null;
  final hour = int.tryParse(match.group(1) ?? '');
  final minute = int.tryParse(match.group(2) ?? '');
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _formatTimeRange(DateTime start, DateTime end) {
  return '${_formatTime(start)} - ${_formatTime(end)}';
}

String _weekLabel(DateTime selectedDay) {
  final monday = selectedDay.subtract(Duration(days: selectedDay.weekday - 1));
  final sunday = monday.add(const Duration(days: 6));
  return '${_formatDate(monday)} - ${_formatDate(sunday)}';
}

class _BlockSpaceDraft {
  const _BlockSpaceDraft({
    required this.start,
    required this.end,
    required this.reason,
  });

  final DateTime start;
  final DateTime end;
  final String reason;
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
    final noSchedule = message.contains('días activos');
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
                  : noSchedule
                  ? Icons.schedule_outlined
                  : Icons.calendar_today_outlined,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            Text(
              isNoBarbershop
                  ? 'Sin barbería asignada'
                  : noSchedule
                  ? 'Sin días activos'
                  : 'Sin citas',
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
            if (isNoBarbershop || noSchedule) ...[
              const SizedBox(height: 32),
              AppFadeSlideIn(
                delay: AppMotion.delay(1),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.go('/cuenta-barbero/mi-horario'),
                    icon: Icon(
                      isNoBarbershop
                          ? Icons.storefront_rounded
                          : Icons.schedule_outlined,
                    ),
                    label: Text(
                      isNoBarbershop ? 'Ir a Barbería' : 'Configurar horario',
                    ),
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
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

({Color background, Color foreground}) _statusStyle(
  AppointmentBookingStatus status,
  ColorScheme colorScheme,
) {
  return switch (status) {
    AppointmentBookingStatus.confirmed => (
      background: colorScheme.primaryContainer,
      foreground: colorScheme.onPrimaryContainer,
    ),
    AppointmentBookingStatus.inProgress => (
      background: colorScheme.primary.withValues(alpha: 0.1),
      foreground: colorScheme.primary,
    ),
    AppointmentBookingStatus.completed => (
      background: colorScheme.surfaceContainerHigh,
      foreground: colorScheme.onSurfaceVariant,
    ),
    AppointmentBookingStatus.pending => (
      background: colorScheme.surfaceContainerHigh,
      foreground: colorScheme.onSurfaceVariant,
    ),
    AppointmentBookingStatus.cancelled => (
      background: colorScheme.errorContainer,
      foreground: colorScheme.onErrorContainer,
    ),
  };
}
