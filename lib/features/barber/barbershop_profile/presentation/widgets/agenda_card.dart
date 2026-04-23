import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../shared/theme/app_theme.dart';
import '../../domain/entities/barbershop.dart';
import '../bloc/booking/booking_cubit.dart';
import '../bloc/booking/booking_state.dart';
import 'day_selector.dart';
import 'selected_barber_tile.dart';
import 'time_slot_grid.dart';

class AgendaCard extends StatelessWidget {
  final Barbershop barbershop;
  const AgendaCard({super.key, required this.barbershop});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 18, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text('Agenda tu Cita', style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          BlocBuilder<BookingCubit, BookingState>(
            buildWhen: (p, c) => p.selectedDay != c.selectedDay,
            builder: (context, state) => DaySelector(
              days: barbershop.availableDays,
              selected: state.selectedDay,
              onSelect: context.read<BookingCubit>().selectDay,
            ),
          ),
          const SizedBox(height: 20),
          BlocBuilder<BookingCubit, BookingState>(
            buildWhen: (p, c) =>
                p.selectedDay != c.selectedDay ||
                p.selectedSlot != c.selectedSlot,
            builder: (context, state) => TimeSlotGrid(
              slots: barbershop.slotsFor(state.selectedDay),
              selected: state.selectedSlot,
              onSelect: context.read<BookingCubit>().selectSlot,
              onJoinWaitlist: () {},
            ),
          ),
          const SizedBox(height: 20),
          BlocBuilder<BookingCubit, BookingState>(
            buildWhen: (p, c) => p.selectedBarber != c.selectedBarber,
            builder: (_, state) =>
                SelectedBarberTile(barber: state.selectedBarber),
          ),
          const SizedBox(height: 12),
          _ConfirmButton(),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      buildWhen: (p, c) =>
          p.canConfirm != c.canConfirm || p.status != c.status,
      builder: (context, state) {
        final submitting = state.status == BookingStatus.submitting;
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: state.canConfirm
                ? () => context.read<BookingCubit>().confirm()
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : const Text('Confirmar Reserva'),
          ),
        );
      },
    );
  }
}