import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/motion/app_motion.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../../../../bookings/domain/entities/booking.dart';
import '../bloc/client_bookings_cubit.dart';

class ClientBookingsScreen extends StatelessWidget {
  const ClientBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<ClientBookingsCubit, ClientBookingsState>(
          builder: (context, state) => switch (state) {
            ClientBookingsLoading() => const _LoadingView(),
            ClientBookingsEmpty() => const _EmptyView(),
            ClientBookingsError(:final message) => _ErrorView(message: message),
            ClientBookingsLoaded() => _LoadedView(state: state),
          },
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.state});

  final ClientBookingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final activeBooking = state.activeBooking;
    final upcoming = state.upcomingBookings
        .where((booking) => booking.id != activeBooking?.id)
        .toList();
    final history = state.historyBookings;
    final penalties = state.penaltyBookings;

    return DefaultTabController(
      length: 3,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppFadeSlideIn(child: _Header()),
            if (activeBooking != null) ...[
              const SizedBox(height: 20),
              AppFadeSlideIn(
                delay: AppMotion.delay(1),
                child: _NextBookingCard(
                  booking: activeBooking,
                  onReschedule: () =>
                      _rescheduleBooking(context, activeBooking),
                  onCancel: () =>
                      _confirmAndCancelBooking(context, activeBooking),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const _BookingsTabs(),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                children: [
                  _BookingListView(
                    bookings: upcoming,
                    emptyMessage: 'No tienes próximas citas.',
                    showReviewAction: false,
                  ),
                  _BookingListView(
                    bookings: history,
                    emptyMessage: 'Tu historial aparecerá aquí.',
                    showReviewAction: true,
                  ),
                  _BookingListView(
                    bookings: penalties,
                    emptyMessage: 'No tienes penalizaciones registradas.',
                    showReviewAction: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingsTabs extends StatelessWidget {
  const _BookingsTabs();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: TabBar(
        labelColor: theme.colorScheme.onSurface,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicatorColor: theme.colorScheme.primary,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Próximas'),
          Tab(text: 'Historial'),
          Tab(text: 'Penalizaciones'),
        ],
      ),
    );
  }
}

class _BookingListView extends StatelessWidget {
  const _BookingListView({
    required this.bookings,
    required this.emptyMessage,
    required this.showReviewAction,
  });

  final List<Booking> bookings;
  final String emptyMessage;
  final bool showReviewAction;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: bookings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _BookingTile(
          booking: booking,
          muted: !booking.isActive,
          onReview:
              showReviewAction &&
                  booking.status == AppointmentBookingStatus.completed &&
                  !booking.isReviewed
              ? () => _reviewBooking(context, booking)
              : null,
        );
      },
    );
  }
}

Future<void> _confirmAndCancelBooking(
  BuildContext context,
  Booking booking,
) async {
  final shouldCancel = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return AlertDialog(
        title: const Text('Cancelar cita'),
        content: Text(
          'Vas a cancelar tu cita de ${booking.serviceSnapshot.name} en ${booking.shopSnapshot.name}.\n\nLa barbería será notificada. Si cancelas con menos de 1 hora de anticipación, puede aplicarse una penalización del 50%.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      );
    },
  );

  if (shouldCancel != true || !context.mounted) {
    return;
  }

  await context.read<ClientBookingsCubit>().cancelBooking(booking);
}

void _rescheduleBooking(BuildContext context, Booking booking) {
  if (booking.barbershopId.isEmpty || booking.barberId.isEmpty) return;

  context.push(
    '/barberia/${booking.barbershopId}/barbero/${booking.barberId}',
    extra: booking,
  );
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mis citas', style: AppTypography.headlineLarge),
        const SizedBox(height: 6),
        Text(
          'Administra tus reservas, reprograma o revisa tu historial.',
          style: AppTypography.bodyMedium.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _NextBookingCard extends StatelessWidget {
  const _NextBookingCard({
    required this.booking,
    required this.onReschedule,
    required this.onCancel,
  });

  final Booking booking;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(
                  Icons.event_available_rounded,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Text(
                  'CITA ACTIVA',
                  style: AppTypography.labelSmall.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            booking.serviceSnapshot.name,
            style: AppTypography.headlineSmall.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_formatDateTime(booking.slotStart)} · ${booking.shopSnapshot.name}',
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onReschedule,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                  ),
                  child: const Text('Reprogramar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(
                      color: colorScheme.error.withValues(alpha: 0.55),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({
    required this.booking,
    this.muted = false,
    this.onReview,
  });

  final Booking booking;
  final bool muted;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _bookingStatusColor(colorScheme, booking);
    final cancellationLabel = _bookingCancellationLabel(booking);
    final penaltyLabel = booking.hasPenalty
        ? 'Penalización: ${_currency(booking.penaltyAmount)} pendiente'
        : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: muted
            ? colorScheme.surfaceContainerLowest
            : statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: statusColor.withValues(alpha: muted ? 0.15 : 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: muted ? colorScheme.surfaceContainerHigh : statusColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              booking.status == AppointmentBookingStatus.cancelled
                  ? Icons.event_busy_rounded
                  : booking.status == AppointmentBookingStatus.completed
                  ? Icons.event_available_rounded
                  : Icons.calendar_today_outlined,
              color: muted
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.serviceSnapshot.name,
                  style: AppTypography.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  '${booking.shopSnapshot.name} · ${_formatDateTime(booking.slotStart)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _BookingChip(
                      label: _bookingStatusLabel(booking),
                      color: statusColor,
                    ),
                    if (cancellationLabel != null)
                      _BookingChip(
                        label: cancellationLabel,
                        color:
                            booking.cancelledBy ==
                                BookingCancellationActor.client
                            ? colorScheme.error
                            : colorScheme.tertiary,
                      ),
                    if (penaltyLabel != null)
                      _BookingChip(
                        label: penaltyLabel,
                        color: colorScheme.error,
                      ),
                    if (booking.status == AppointmentBookingStatus.completed)
                      _BookingChip(
                        label: booking.isReviewed ? 'Reseñada' : 'Sin reseña',
                        color: booking.isReviewed
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
                if ((booking.cancellationReason ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Motivo: ${booking.cancellationReason!.trim()}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (booking.cancelledAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Cancelada el ${_formatDateTime(booking.cancelledAt!)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (booking.reviewedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Reseñada el ${_formatDateTime(booking.reviewedAt!)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                booking.status.label,
                style: AppTypography.labelSmall.copyWith(
                  color: muted ? colorScheme.onSurfaceVariant : statusColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (onReview != null) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: onReview,
                  child: const Text('Calificar'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingChip extends StatelessWidget {
  const _BookingChip({required this.label, required this.color});

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

Future<void> _reviewBooking(BuildContext context, Booking booking) async {
  int rating = 5;
  var comment = '';

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Calificar cita'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.serviceSnapshot.name,
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4,
                  children: List.generate(5, (index) {
                    final star = index + 1;
                    final selected = star <= rating;
                    return IconButton(
                      onPressed: () => setState(() => rating = star),
                      icon: Icon(
                        selected
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  maxLines: 3,
                  onChanged: (value) => comment = value,
                  decoration: const InputDecoration(
                    labelText: 'Comentario (opcional)',
                    hintText: 'Contá cómo te fue con el servicio',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: rating < 1
                    ? null
                    : () => Navigator.of(dialogContext).pop(true),
                child: const Text('Publicar'),
              ),
            ],
          );
        },
      );
    },
  );

  if (result != true || !context.mounted) return;

  try {
    final success = await context.read<ClientBookingsCubit>().createReview(
      booking: booking,
      rating: rating,
      comment: comment,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Reseña publicada' : 'No se pudo publicar la reseña',
        ),
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo publicar la reseña')),
    );
  }
}

Color _bookingStatusColor(ColorScheme colorScheme, Booking booking) {
  return switch (booking.status) {
    AppointmentBookingStatus.pending => colorScheme.primary,
    AppointmentBookingStatus.confirmed => colorScheme.primary,
    AppointmentBookingStatus.inProgress => colorScheme.tertiary,
    AppointmentBookingStatus.completed => colorScheme.onSurfaceVariant,
    AppointmentBookingStatus.cancelled =>
      booking.cancelledBy == BookingCancellationActor.client
          ? colorScheme.error
          : colorScheme.tertiary,
  };
}

String _bookingStatusLabel(Booking booking) {
  return switch (booking.status) {
    AppointmentBookingStatus.pending => 'Pendiente',
    AppointmentBookingStatus.confirmed => 'Confirmada',
    AppointmentBookingStatus.inProgress => 'En curso',
    AppointmentBookingStatus.completed => 'Completada',
    AppointmentBookingStatus.cancelled => 'Cancelada',
  };
}

String? _bookingCancellationLabel(Booking booking) {
  if (booking.status != AppointmentBookingStatus.cancelled ||
      booking.cancelledBy == null) {
    return null;
  }

  return booking.cancelledBy == BookingCancellationActor.client
      ? 'Cancelada por vos'
      : 'Cancelada por barbería';
}

String _currency(double value) => '₡${value.toStringAsFixed(0)}';

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
    return const Center(child: Text('Todavía no tienes citas.'));
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

String _formatDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '$day/$month · $hour:$minute $period';
}
