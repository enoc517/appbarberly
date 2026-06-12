import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/app_dependencies.dart';
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
            ClientBookingsLoaded(:final bookings) => _LoadedView(
              bookings: bookings,
              activeBooking: state.activeBooking,
            ),
          },
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({required this.bookings, required this.activeBooking});

  final List<Booking> bookings;
  final Booking? activeBooking;

  @override
  Widget build(BuildContext context) {
    final history = bookings.where((booking) => !booking.isActive).toList();
    final upcoming = bookings.where((booking) => booking.isActive).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        const AppFadeSlideIn(child: _Header()),
        const SizedBox(height: 20),
        if (activeBooking != null)
          AppFadeSlideIn(
            delay: AppMotion.delay(1),
            child: _NextBookingCard(
              booking: activeBooking!,
              onReschedule: () => _rescheduleBooking(context, activeBooking!),
              onCancel: () => _confirmAndCancelBooking(context, activeBooking!),
            ),
          ),
        if (activeBooking == null) const _NoActiveBookingCard(),
        const SizedBox(height: 24),
        const _SectionTitle(title: 'Próximas citas'),
        const SizedBox(height: 12),
        if (upcoming.isEmpty)
          const _InlineEmpty(message: 'No tienes citas activas.'),
        for (final booking in upcoming) ...[
          _BookingTile(booking: booking),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 14),
        const _SectionTitle(title: 'Historial'),
        const SizedBox(height: 12),
        if (history.isEmpty)
          const _InlineEmpty(message: 'Tu historial aparecerá aquí.'),
        for (final booking in history) ...[
          _BookingTile(
            booking: booking,
            muted: true,
            onReview: booking.status == AppointmentBookingStatus.completed &&
                    !booking.isReviewed
                ? () => _reviewBooking(context, booking)
                : null,
          ),
          const SizedBox(height: 10),
        ],
      ],
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

class _NoActiveBookingCard extends StatelessWidget {
  const _NoActiveBookingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Text(
        'No tienes una cita activa. Puedes reservar desde Explorar.',
        style: AppTypography.bodyMedium.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: muted
                  ? theme.colorScheme.surfaceContainerHigh
                  : theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              color: muted
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onPrimary,
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
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if ((booking.cancellationReason ?? '').trim().isNotEmpty) ...[
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
                if (booking.isReviewed) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Reseñada',
                    style: AppTypography.labelSmall.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
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
                  color: muted
                      ? theme.colorScheme.onSurfaceVariant
                      : _statusColor(theme.colorScheme, booking.status),
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
                        selected ? Icons.star_rounded : Icons.star_border_rounded,
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
    await AppDependencies.reviewsRepository.createReview(
      bookingId: booking.id,
      clientId: booking.clientId,
      rating: rating,
      comment: comment,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reseña publicada')),
    );
  } catch (error) {
    if (!context.mounted) return;
    final message = error is StateError ? error.message : error.toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTypography.titleLarge);
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

Color _statusColor(ColorScheme colorScheme, AppointmentBookingStatus status) {
  return switch (status) {
    AppointmentBookingStatus.pending => colorScheme.primary,
    AppointmentBookingStatus.confirmed => colorScheme.primary,
    AppointmentBookingStatus.inProgress => colorScheme.tertiary,
    AppointmentBookingStatus.completed => colorScheme.onSurfaceVariant,
    AppointmentBookingStatus.cancelled => colorScheme.error,
  };
}
