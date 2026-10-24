import 'package:bakery_mobile/src/features/admin/content/notifications/domain/models/admin_notification.dart';

/// Parses the `{notifications, pagination}` list envelope.
class NotificationAdminListDto {
  const NotificationAdminListDto._();

  static NotificationAdminPage fromJson(Map<String, dynamic> data) {
    final rows = data['notifications'];
    final pagination = data['pagination'];
    return NotificationAdminPage(
      items: rows is List<dynamic>
          ? [
              for (final row in rows)
                if (row is Map<String, dynamic>)
                  NotificationAdminDto.fromJson(row),
            ]
          : const [],
      total: pagination is Map<String, dynamic>
          ? (pagination['total'] is num
                ? (pagination['total'] as num).toInt()
                : 0)
          : 0,
      totalPages: pagination is Map<String, dynamic>
          ? (pagination['totalPages'] is num
                ? (pagination['totalPages'] as num).toInt()
                : 1)
          : 1,
    );
  }
}

class NotificationAdminDto {
  const NotificationAdminDto._();

  static AdminNotification fromJson(Map<String, dynamic> json) {
    return AdminNotification(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      imageUrl: json['imageUrl']?.toString(),
      linkUrl: json['linkUrl']?.toString(),
      audience: json['audience']?.toString(),
      status: notificationStatusFrom((json['status'] ?? '').toString()),
      createdAt:
          DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
    );
  }
}

class NotificationAdminPage {
  const NotificationAdminPage({
    required this.items,
    required this.total,
    required this.totalPages,
  });

  final List<AdminNotification> items;
  final int total;
  final int totalPages;
}
