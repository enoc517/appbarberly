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
    final theme = Theme.of(context);
    final isNow = appointment.isNow;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: isNow
            ? Border.all(color: theme.colorScheme.secondary, width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          _ClientAvatar(imageUrl: appointment.clientAvatarUrl),
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
                          color: theme.colorScheme.secondary,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          'AHORA',
                          style: AppTypography.labelSmall.copyWith(
                            color: theme.colorScheme.onSecondary,
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
                    color: theme.colorScheme.onSurfaceVariant,
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

class _ClientAvatar extends StatelessWidget {
  const _ClientAvatar({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final normalizedUrl = imageUrl?.trim() ?? '';

    return CircleAvatar(
      radius: 24,
      backgroundColor: colorScheme.primaryContainer,
      backgroundImage: normalizedUrl.isEmpty
          ? null
          : NetworkImage(normalizedUrl),
      child: normalizedUrl.isEmpty
          ? Icon(Icons.person_rounded, color: colorScheme.onPrimaryContainer)
          : null,
    );
  }
}
