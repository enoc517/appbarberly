import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/../../../shared/theme/app_theme.dart';

class DashboardHeader extends StatelessWidget {
  final DateTime today;
  final int unreadNotifications;
  const DashboardHeader({
    super.key,
    required this.today,
    this.unreadNotifications = 0,
  });

  static const _months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.cut,
                  color: theme.colorScheme.onPrimary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text('Barberly', style: AppTypography.titleLarge),
              const Spacer(),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () => context.push('/notificaciones'),
                    icon: const Icon(Icons.notifications_outlined),
                  ),
                  if (unreadNotifications > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          unreadNotifications > 9
                              ? '9+'
                              : '$unreadNotifications',
                          textAlign: TextAlign.center,
                          style: AppTypography.labelSmall.copyWith(
                            color: theme.colorScheme.onSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Tu día', style: AppTypography.headlineLarge),
          const SizedBox(height: 4),
          Text(
            'Resumen personal para hoy, ${today.day} de ${_months[today.month - 1]}',
            style: AppTypography.bodyMedium.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
