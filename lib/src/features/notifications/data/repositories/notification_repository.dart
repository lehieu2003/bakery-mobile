import 'package:bakery_mobile/src/features/notifications/data/datasources/notification_api_service.dart';
import 'package:bakery_mobile/src/features/notifications/domain/models/app_notification.dart';

class NotificationListResult {
  const NotificationListResult({
    required this.notifications,
    required this.total,
  });

  final List<AppNotification> notifications;
  final int total;
}

class NotificationRepository {
  NotificationRepository(this._notificationApiService);

  final NotificationApiService _notificationApiService;

  Future<NotificationListResult> getMyNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final result = await _notificationApiService.getMyNotifications(
      page: page,
      limit: limit,
      unreadOnly: unreadOnly,
    );
    return NotificationListResult(
      notifications: result.notifications.map((e) => e.toDomain()).toList(),
      total: result.total,
    );
  }

  Future<void> markAsRead(String id) => _notificationApiService.markAsRead(id);

  Future<void> markAllAsRead() => _notificationApiService.markAllAsRead();
}
