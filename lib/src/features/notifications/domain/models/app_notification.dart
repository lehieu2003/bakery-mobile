class AppNotification {
  const AppNotification({
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

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
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

  AppNotification copyWith({bool? isRead, DateTime? readAt}) {
    return AppNotification(
      id: id,
      title: title,
      content: content,
      linkUrl: linkUrl,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      publishedAt: publishedAt,
      createdAt: createdAt,
    );
  }
}

