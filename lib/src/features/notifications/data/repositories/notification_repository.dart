import 'package:bakery_mobile/src/features/notifications/data/datasources/notification_api_service.dart';

class NotificationRepository {
  NotificationRepository(this._notificationApiService);

  final NotificationApiService _notificationApiService;

  Future<NotificationListResult> getMyNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) {
    return _notificationApiService.getMyNotifications(
      page: page,
      limit: limit,
      unreadOnly: unreadOnly,
    );
  }

  Future<void> markAsRead(String id) => _notificationApiService.markAsRead(id);

  Future<void> markAllAsRead() => _notificationApiService.markAllAsRead();
}


