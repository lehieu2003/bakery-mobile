import 'package:bakery_mobile/src/features/admin/content/pages/domain/models/admin_page.dart';

/// Parses one static page row; the list endpoint returns a bare array.
class PageAdminDto {
  const PageAdminDto._();

  static AdminPage fromJson(Map<String, dynamic> json) {
    return AdminPage(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      isPublished: json['isPublished'] == true,
      createdAt:
          DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
    );
  }

  static List<AdminPage> listFrom(dynamic data) {
    if (data is! List<dynamic>) return const [];
    return [
      for (final row in data)
        if (row is Map<String, dynamic>) fromJson(row),
    ];
  }
}
