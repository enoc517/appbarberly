import 'package:flutter/material.dart';
import '/../../../shared/theme/app_theme.dart';
import '../../domain/entities/appointment.dart';
import 'appointment_tile.dart';

class AgendaTimeline extends StatelessWidget {
  final List<Appointment> appointments;

  const AgendaTimeline({super.key, required this.appointments});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < appointments.length; i++) ...[
          _TimelineRow(
            appointment: appointments[i],
            isLast: i == appointments.length - 1,
          ),
          if (i != appointments.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final Appointment appointment;
  final bool isLast;

  const _TimelineRow({required this.appointment, required this.isLast});

  String _hhmm(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isNow = appointment.isNow;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                _hhmm(appointment.startTime),
                style: AppTypography.labelLarge.copyWith(
                  color: isNow ? AppColors.secondary : AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 24),
              Container(width: 2, height: 12, color: AppColors.outlineVariant),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: AppColors.outlineVariant),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppointmentTile(appointment: appointment, onMessage: () {}),
          ),
        ],
      ),
    );
  }
}
