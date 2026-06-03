import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

sealed class NotificationsState {
  const NotificationsState();

  int get unreadCount => 0;
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded(this.notifications);

  final List<AppNotification> notifications;

  @override
  int get unreadCount => notifications.where((n) => !n.isRead).length;
}

class NotificationsEmpty extends NotificationsState {
  const NotificationsEmpty();
}

class NotificationsError extends NotificationsState {
  const NotificationsError(this.message);

  final String message;
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required NotificationsRepository repository,
    required String userId,
  }) : _repository = repository,
       _userId = userId,
       super(const NotificationsLoading());

  final NotificationsRepository _repository;
  final String _userId;
  StreamSubscription<List<AppNotification>>? _subscription;

  void watch() {
    if (_userId.isEmpty) {
      emit(const NotificationsEmpty());
      return;
    }

    _subscription?.cancel();
    _subscription = _repository
        .watchUserNotifications(_userId)
        .listen(
          (notifications) => emit(
            notifications.isEmpty
                ? const NotificationsEmpty()
                : NotificationsLoaded(notifications),
          ),
          onError: (_) => emit(
            const NotificationsError(
              'No se pudieron cargar las notificaciones',
            ),
          ),
        );
  }

  Future<void> markAsRead(AppNotification notification) async {
    if (notification.isRead) return;
    try {
      await _repository.markAsRead(notification.id);
    } catch (_) {
      emit(const NotificationsError('No se pudo marcar como leída'));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
