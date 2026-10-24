/// Admin notification row. Statuses mirror the server enum.
enum NotificationStatus { draft, published, archived }

NotificationStatus notificationStatusFrom(String raw) {
  switch (raw) {
    case 'PUBLISHED':
      return NotificationStatus.published;
    case 'ARCHIVED':
      return NotificationStatus.archived;
    default:
      return NotificationStatus.draft;
  }
}

class AdminNotification {
  const AdminNotification({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    this.linkUrl,
    this.audience,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final String? linkUrl;

  /// e.g. `GLOBAL` / `USER`; null when the row predates the field.
  final String? audience;
  final NotificationStatus status;
  final DateTime createdAt;
}
