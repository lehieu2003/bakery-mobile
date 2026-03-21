import 'package:bakery_mobile/src/features/notifications/domain/models/app_notification.dart';

class AppNotificationDto {
  const AppNotificationDto({
    required this.id,
    required this.title,
    required this.content,
    this.linkUrl,
    required this.isRead,
    this.readAt,
    this.publishedAt,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String content;
  final String? linkUrl;
  final bool isRead;
  final DateTime? readAt;
  final DateTime? publishedAt;
  final DateTime createdAt;

  factory AppNotificationDto.fromJson(Map<String, dynamic> json) {
    return AppNotificationDto(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      linkUrl: json['linkUrl']?.toString(),
      isRead: json['isRead'] == true,
      readAt: DateTime.tryParse('${json['readAt'] ?? ''}'),
      publishedAt: DateTime.tryParse('${json['publishedAt'] ?? ''}'),
      createdAt:
          DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
    );
  }

  AppNotification toDomain() {
    return AppNotification(
      id: id,
      title: title,
      content: content,
      linkUrl: linkUrl,
      isRead: isRead,
      readAt: readAt,
      publishedAt: publishedAt,
      createdAt: createdAt,
    );
  }
}

class NotificationListResultDto {
  const NotificationListResultDto({
    required this.notifications,
    required this.total,
  });

  final List<AppNotificationDto> notifications;
  final int total;
}
