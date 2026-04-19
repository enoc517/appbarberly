import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/../../../shared/theme/app_theme.dart';
import '../bloc/dashboard_cubit.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/agenda_timeline.dart';
import '../widgets/completed_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/income_card.dart';
import '../widgets/weekly_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) => switch (state) {
            DashboardLoading() =>
              const Center(child: CircularProgressIndicator()),
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
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        DashboardHeader(today: DateTime.now()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: IncomeCard(
            income: data.summary.incomeToday,
            deltaPercent: data.summary.incomeDeltaPercent,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CompletedCard(
            completed: data.summary.completedAppointments,
            total: data.summary.totalAppointments,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: WeeklyChart(data: data.weekly),
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
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AgendaTimeline(appointments: data.todayAppointments),
        ),
      ],
    );
  }
}