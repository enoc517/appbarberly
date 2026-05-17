import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/motion/app_motion.dart';
import '../cubit/barber_booking_cubit.dart';
import '../cubit/barber_booking_state.dart';

class BarberBookingScreen extends StatelessWidget {
  final String shopId;
  final String barberId;
  final String? clientId;

  const BarberBookingScreen({
    super.key,
    required this.shopId,
    required this.barberId,
    this.clientId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BarberBookingCubit(
        shopId: shopId,
        barberId: barberId,
        clientId: clientId,
      )..loadData(),
      child: const _BarberBookingView(),
    );
  }
}

class _BarberBookingView extends StatelessWidget {
  const _BarberBookingView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<BarberBookingCubit, BarberBookingState>(
      listenWhen: (prev, curr) => prev.isBooking != curr.isBooking || prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.errorMessage}')),
          );
        }
        if (!state.isBooking && state.errorMessage == null && state.canConfirm) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reserva confirmada')),
          );
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: BlocBuilder<BarberBookingCubit, BarberBookingState>(
            builder: (context, state) => Text(
              state.barberName ?? 'Barbero',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.onSurface,
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
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (state.services.isEmpty)
                Text(
                  'No hay servicios disponibles',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.onSurfaceVariant,
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
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (state.availableDays.isEmpty)
                  Text(
                    'No hay días disponibles',
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.onSurfaceVariant,
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
                            color: selected ? AppColors.onPrimary : AppColors.onSurface,
                          ),
                        ),
                        selected: selected,
                        selectedColor: AppColors.primaryContainer,
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
                      color: AppColors.onSurface,
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
                          color: selected ? AppColors.onPrimary : AppColors.onSurface,
                        ),
                      ),
                      selected: selected,
                      selectedColor: AppColors.primaryContainer,
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
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.onSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                    ),
                    child: state.isBooking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onSecondary,
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
    return BlocBuilder<BarberBookingCubit, BarberBookingState>(
      buildWhen: (prev, curr) => prev.selectedService != curr.selectedService,
      builder: (context, state) {
        final selected = state.selectedService?['id'] == service['id'];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: selected ? AppColors.primaryContainer.withValues(alpha: 0.1) : null,
          child: ListTile(
            title: Text(
              service['name'] as String,
              style: AppTypography.titleMedium.copyWith(color: AppColors.onSurface),
            ),
            subtitle: Text(
              '₡${(service['price'] as num).toStringAsFixed(0)} — ${service['durationMinutes']}min',
              style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
            ),
            onTap: () => context.read<BarberBookingCubit>().selectService(service),
          ),
        );
      },
    );
  }
}
