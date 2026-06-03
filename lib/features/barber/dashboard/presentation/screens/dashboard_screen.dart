import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/../../../shared/motion/app_motion.dart';
import '/../../../shared/theme/app_theme.dart';
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
  final dynamic data; // DashboardData
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
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Text('Agenda de hoy', style: AppTypography.headlineSmall),
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
          delay: AppMotion.delay(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AgendaTimeline(appointments: data.todayAppointments),
          ),
        ),
      ],
    );
  }
}
