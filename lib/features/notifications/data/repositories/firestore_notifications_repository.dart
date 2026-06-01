import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

class FirestoreNotificationsRepository implements NotificationsRepository {
  FirestoreNotificationsRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');

  @override
  Stream<List<AppNotification>> watchUserNotifications(String userId) {
    return _notifications
        .where('recipientId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map(_AppNotificationModel.fromDocument)
              .toList();
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notifications;
        });
  }

  @override
  Future<void> markAsRead(String notificationId) {
    return _notifications.doc(notificationId).set({
      'readAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

class _AppNotificationModel extends AppNotification {
  const _AppNotificationModel({
    required super.id,
    required super.recipientId,
    required super.recipientRole,
    required super.type,
    required super.title,
    required super.body,
    required super.createdAt,
    super.bookingId,
    super.barbershopId,
    super.penaltyId,
    super.readAt,
  });

  factory _AppNotificationModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return _AppNotificationModel(
      id: doc.id,
      recipientId: data['recipientId'] as String? ?? '',
      recipientRole: data['recipientRole'] as String? ?? '',
      type: _type(data['type'] as String?),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      bookingId: data['bookingId'] as String?,
      barbershopId: data['barbershopId'] as String?,
      penaltyId: data['penaltyId'] as String?,
      createdAt: _dateTime(data['createdAt']),
      readAt: _nullableDateTime(data['readAt']),
    );
  }

  static AppNotificationType _type(String? value) {
    return AppNotificationType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => AppNotificationType.bookingCancelled,
    );
  }

  static DateTime _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _nullableDateTime(Object? value) {
    if (value == null) return null;
    return _dateTime(value);
  }
}
