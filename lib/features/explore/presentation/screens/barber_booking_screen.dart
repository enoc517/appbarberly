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
      listenWhen: (prev, curr) => prev.isBooking != curr.isBooking || prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppToast.error(context, 'Error: ${state.errorMessage}');
        }
        if (!state.isBooking && state.errorMessage == null && state.canConfirm) {
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
          buildWhen: (prev, curr) => prev.isLoading != curr.isLoading,
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return const _BookingContent();
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
          padding: const EdgeInsets.all(20),
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.availableDays.map((day) {
                      final selected = state.selectedDay == day;
                      return ChoiceChip(
                        label: Text(
                          '${day.day}/${day.month}',
                          style: TextStyle(
                            color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                          ),
                        ),
                        selected: selected,
                        selectedColor: theme.colorScheme.primaryContainer,
                        onSelected: (_) => context.read<BarberBookingCubit>().selectDay(day),
                      );
                    }).toList(),
                  ),
              ],
              const SizedBox(height: 24),
              if (state.selectedDay != null) ...[
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _generateTimeSlots().map((time) {
                    final selected = state.selectedTime == time;
                    return ChoiceChip(
                      label: Text(
                        time,
                        style: TextStyle(
                          color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                        ),
                      ),
                      selected: selected,
                      selectedColor: theme.colorScheme.primaryContainer,
                      onSelected: (_) => context.read<BarberBookingCubit>().selectTime(time),
                    );
                  }).toList(),
                ),
              ],
              if (state.selectedTime != null) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: state.canConfirm
                        ? () => context.read<BarberBookingCubit>().confirmBooking()
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                    ),
                    child: state.isBooking
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onSecondary,
                            ),
                          )
                        : const Text(
                            'Confirmar reserva',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  List<String> _generateTimeSlots() {
    final slots = <String>[];
    for (var hour = 8; hour < 20; hour++) {
      slots.add('${hour.toString().padLeft(2, '0')}:00');
      slots.add('${hour.toString().padLeft(2, '0')}:30');
    }
    return slots;
  }
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
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: selected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1) : null,
          child: ListTile(
            title: Text(
              service['name'] as String,
              style: AppTypography.titleMedium.copyWith(color: theme.colorScheme.onSurface),
            ),
            subtitle: Text(
              '₡${(service['price'] as num).toStringAsFixed(0)} — ${service['durationMinutes']}min',
              style: AppTypography.bodySmall.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            onTap: () => context.read<BarberBookingCubit>().selectService(service),
          ),
        );
      },
    );
  }
}
