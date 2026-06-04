import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../domain/entities/app_notification.dart';
import '../cubit/notifications_cubit.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final unreadCount = state.unreadCount;
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notificaciones',
                  style: AppTypography.titleLarge.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  unreadCount == 0 ? 'Todo al día' : '$unreadCount sin leer',
                  style: AppTypography.labelMedium.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              if (state is NotificationsLoaded &&
                  state.notifications.isNotEmpty)
                TextButton(
                  onPressed: unreadCount == 0
                      ? null
                      : () =>
                            context.read<NotificationsCubit>().markAllAsRead(),
                  child: const Text('Marcar todas'),
                ),
            ],
          ),
          body: SafeArea(
            child: switch (state) {
              NotificationsLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              NotificationsEmpty() => const _EmptyState(),
              NotificationsError(:final message) => _ErrorState(
                message: message,
              ),
              NotificationsLoaded(:final notifications) => _NotificationsList(
                notifications: notifications,
              ),
            },
          ),
        );
      },
    );
  }
}

class _NotificationsList extends StatelessWidget {
  const _NotificationsList({required this.notifications});

  final List<AppNotification> notifications;

  @override
  Widget build(BuildContext context) {
    final unread = notifications.where((n) => !n.isRead).toList();
    final read = notifications.where((n) => n.isRead).toList();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      itemCount:
          (unread.isEmpty ? 0 : 1) +
          unread.length +
          (read.isEmpty ? 0 : 1) +
          read.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (unread.isNotEmpty) {
          if (index == 0) return const _SectionHeader(title: 'Nuevas');
          final unreadIndex = index - 1;
          if (unreadIndex < unread.length) {
            return _NotificationCard(notification: unread[unreadIndex]);
          }
        }

        final readSectionOffset = (unread.isEmpty ? 0 : 1) + unread.length;
        if (read.isNotEmpty) {
          if (index == readSectionOffset) {
            return const _SectionHeader(title: 'Leídas');
          }
          final readIndex = index - readSectionOffset - 1;
          if (readIndex < read.length) {
            return _NotificationCard(notification: read[readIndex]);
          }
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        title,
        style: AppTypography.labelLarge.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = notification.isRead
        ? colorScheme.onSurfaceVariant
        : colorScheme.secondary;

    return Semantics(
      button: true,
      selected: !notification.isRead,
      label:
          '${notification.isRead ? 'Notificación leída' : 'Notificación nueva'}: ${notification.title}. ${notification.body}',
      child: Material(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          onTap: () async {
            await context.read<NotificationsCubit>().markAsRead(notification);
            if (!context.mounted) return;
            final destination = _destinationFor(notification);
            if (destination != null) context.go(destination);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Icon(_iconFor(notification.type), color: accentColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppTypography.titleSmall.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w900,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.full,
                                ),
                              ),
                              child: Text(
                                'Nueva',
                                style: AppTypography.labelSmall.copyWith(
                                  color: colorScheme.secondary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDateTime(notification.createdAt),
                        style: AppTypography.labelSmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(AppNotificationType type) => switch (type) {
    AppNotificationType.bookingCreated => Icons.notifications_active_rounded,
    AppNotificationType.bookingReminder => Icons.event_available_rounded,
    AppNotificationType.bookingCancelled => Icons.event_busy_rounded,
    AppNotificationType.lateCancellationPenalty => Icons.request_quote_rounded,
    AppNotificationType.penaltyResolved => Icons.check_circle_rounded,
  };
}

String? _destinationFor(AppNotification notification) {
  return switch (notification.type) {
    AppNotificationType.bookingCreated =>
      notification.recipientRole == 'barber' ? AppRouter.agenda : null,
    AppNotificationType.bookingReminder =>
      notification.recipientRole == 'client'
          ? AppRouter.citas
          : AppRouter.agenda,
    AppNotificationType.bookingCancelled =>
      notification.recipientRole == 'barber'
          ? AppRouter.agenda
          : AppRouter.citas,
    AppNotificationType.lateCancellationPenalty =>
      notification.recipientRole == 'barber'
          ? '/cuenta-barbero/penalizaciones'
          : AppRouter.citas,
    AppNotificationType.penaltyResolved => AppRouter.citas,
  };
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Todavía no tienes notificaciones.',
              textAlign: TextAlign.center,
              style: AppTypography.titleLarge.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aquí verás cambios en tus citas, cancelaciones y penalizaciones.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/${date.year} · $hour:$minute';
}
