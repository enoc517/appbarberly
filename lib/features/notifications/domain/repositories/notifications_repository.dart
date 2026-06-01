import '../entities/app_notification.dart';

abstract class NotificationsRepository {
  Stream<List<AppNotification>> watchUserNotifications(String userId);

  Future<void> markAsRead(String notificationId);
}
