import 'package:flutter/material.dart';
import '/../../../shared/theme/app_theme.dart';
import '../../domain/entities/appointment.dart';

class AppointmentTile extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback onMessage;

  const AppointmentTile({
    super.key,
    required this.appointment,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isNow = appointment.isNow;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: isNow
            ? Border.all(color: AppColors.secondary, width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryFixedDim,
            child: const Icon(Icons.person, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        appointment.clientName,
                        style: AppTypography.titleSmall,
                      ),
                    ),
                    if (isNow) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          'AHORA',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.onSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  appointment.serviceName,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onMessage,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFE8F5E9),
              padding: const EdgeInsets.all(8),
            ),
            icon: const Icon(
              Icons.chat_bubble_outline,
              color: Color(0xFF4CAF50),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}