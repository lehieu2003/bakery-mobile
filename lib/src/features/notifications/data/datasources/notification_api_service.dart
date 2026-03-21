import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/features/notifications/domain/models/app_notification.dart';

class NotificationListResult {
  const NotificationListResult({
    required this.notifications,
    required this.total,
  });

  final List<AppNotification> notifications;
  final int total;
}

class NotificationApiService {
  NotificationApiService(this._client);

  final ApiClient _client;

  Future<NotificationListResult> getMyNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final response = await _client.get(
      '/api/notifications',
      query: {'page': page, 'limit': limit, if (unreadOnly) 'unreadOnly': true},
    );

    final data = response as Map<String, dynamic>;
    final pagination = data['pagination'] as Map<String, dynamic>? ?? const {};
    final raw = data['notifications'] as List<dynamic>? ?? const [];

    return NotificationListResult(
      notifications: raw
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList(),
      total: pagination['total'] is int
          ? pagination['total'] as int
          : int.tryParse('${pagination['total'] ?? ''}') ?? 0,
    );
  }

  Future<void> markAsRead(String id) async {
    await _client.post('/api/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _client.post('/api/notifications/read-all');
  }
}


