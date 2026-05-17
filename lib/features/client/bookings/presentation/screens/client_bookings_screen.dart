import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../shared/motion/app_motion.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../../../../bookings/domain/entities/booking.dart';
import '../bloc/client_bookings_cubit.dart';

class ClientBookingsScreen extends StatelessWidget {
  const ClientBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
            child: _NextBookingCard(booking: activeBooking!),
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
          _BookingTile(booking: booking, muted: true),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mis citas', style: AppTypography.headlineLarge),
        const SizedBox(height: 6),
        Text(
          'Administra tus reservas, reprograma o revisa tu historial.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _NextBookingCard extends StatelessWidget {
  const _NextBookingCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CITA ACTIVA',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.onPrimaryContainer,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            booking.serviceSnapshot.name,
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatDateTime(booking.slotStart)} · ${booking.shopSnapshot.name}',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.onSecondary,
            ),
            child: const Text('Ver detalle'),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Text(
        'No tienes una cita activa. Puedes reservar desde Explorar.',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking, this.muted = false});

  final Booking booking;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.ghostBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: muted ? AppColors.surfaceContainerHigh : AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.calendar_today_outlined,
              color: muted ? AppColors.onSurfaceVariant : AppColors.onPrimary,
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
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            booking.status.label,
            style: AppTypography.labelSmall.copyWith(
              color: muted ? AppColors.onSurfaceVariant : AppColors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
    return Text(
      message,
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.onSurfaceVariant,
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
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month · $hour:$minute';
}
