import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/../../../shared/motion/app_motion.dart';
import '/../../../shared/theme/app_theme.dart';
import '../../domain/entities/appointment.dart';
import '../../domain/entities/dashboard_overview.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../bloc/dashboard_cubit.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/agenda_timeline.dart';
import '../widgets/completed_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/income_card.dart';
import '../widgets/weekly_chart.dart';
import 'package:barberly/features/notifications/presentation/cubit/notifications_cubit.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) => switch (state) {
            DashboardLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            DashboardError(:final message) => Center(child: Text(message)),
            DashboardLoaded(:final data) => _Content(data: data),
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final DashboardData data;
  const _Content({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        AppFadeSlideIn(
          child: BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, notificationState) => DashboardHeader(
              today: DateTime.now(),
              unreadNotifications: notificationState.unreadCount,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppFadeSlideIn(
            delay: AppMotion.delay(1),
            child: IncomeCard(
              income: data.summary.incomeToday,
              deltaPercent: data.summary.incomeDeltaPercent,
              estimatedIncome: data.summary.estimatedIncomeToday,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppFadeSlideIn(
            delay: AppMotion.delay(2),
            child: CompletedCard(
              completed: data.summary.completedAppointments,
              total: data.summary.totalAppointments,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppFadeSlideIn(
            delay: AppMotion.delay(3),
            child: WeeklyChart(data: data.weekly),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppFadeSlideIn(
            delay: AppMotion.delay(4),
            child: _NextAppointmentCard(appointment: data.nextAppointment),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppFadeSlideIn(
            delay: AppMotion.delay(5),
            child: _WeekOverviewCard(overview: data.weekOverview),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppFadeSlideIn(
            delay: AppMotion.delay(6),
            child: _TopServicesCard(services: data.topServices),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppFadeSlideIn(
            delay: AppMotion.delay(7),
            child: _BlockedHoursCard(blockedHours: data.upcomingBlockedHours),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Text('Tu agenda de hoy', style: AppTypography.headlineSmall),
              const Spacer(),
              Text(
                '${data.summary.pendingAppointments} pendientes',
                style: AppTypography.labelLarge.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        AppFadeSlideIn(
          delay: AppMotion.delay(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AgendaTimeline(appointments: data.todayAppointments),
          ),
        ),
      ],
    );
  }
}

class _NextAppointmentCard extends StatelessWidget {
  const _NextAppointmentCard({required this.appointment});

  final Appointment? appointment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Próxima cita',
            style: AppTypography.labelMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          if (appointment == null)
            Text(
              'No tienes citas próximas.',
              style: AppTypography.bodyMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.event_available_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment!.clientName,
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${appointment!.serviceName} · ${_formatTime(appointment!.startTime)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _WeekOverviewCard extends StatelessWidget {
  const _WeekOverviewCard({required this.overview});

  final BarberWeeklyOverview overview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tu semana', style: AppTypography.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MiniMetric(
                label: 'Total',
                value: overview.totalAppointments.toString(),
              ),
              _MiniMetric(
                label: 'Completadas',
                value: overview.completedAppointments.toString(),
              ),
              _MiniMetric(
                label: 'Canceladas',
                value: overview.cancelledAppointments.toString(),
              ),
              _MiniMetric(
                label: 'Pendientes',
                value: overview.upcomingAppointments.toString(),
              ),
              _MiniMetric(
                label: 'Estimado',
                value: '\$${overview.estimatedIncome.toStringAsFixed(2)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopServicesCard extends StatelessWidget {
  const _TopServicesCard({required this.services});

  final List<ServicePerformance> services;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tus servicios más pedidos', style: AppTypography.titleLarge),
          const SizedBox(height: 12),
          if (services.isEmpty)
            Text(
              'Todavía no hay datos suficientes.',
              style: AppTypography.bodyMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final service in services) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      service.serviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${service.count} · \$${service.estimatedIncome.toStringAsFixed(2)}',
                    style: AppTypography.labelLarge.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (service != services.last) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _BlockedHoursCard extends StatelessWidget {
  const _BlockedHoursCard({required this.blockedHours});

  final List<BlockedTimeBlock> blockedHours;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleBlocks = blockedHours.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Horas bloqueadas próximas', style: AppTypography.titleLarge),
          const SizedBox(height: 12),
          if (blockedHours.isEmpty)
            Text(
              'No hay bloqueos próximos.',
              style: AppTypography.bodyMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            for (final block in visibleBlocks) ...[
              Text(
                '${_formatTime(block.start)} - ${_formatTime(block.end)}',
                style: AppTypography.titleSmall,
              ),
              Text(
                block.reason,
                style: AppTypography.bodySmall.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (block != visibleBlocks.last) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 132,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
