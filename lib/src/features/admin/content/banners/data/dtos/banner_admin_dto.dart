import 'package:bakery_mobile/src/features/admin/content/banners/domain/models/admin_banner.dart';

/// Parses one banner row; the list endpoint returns a bare array.
class BannerAdminDto {
  const BannerAdminDto._();

  static AdminBanner fromJson(Map<String, dynamic> json) {
    return AdminBanner(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      linkUrl: json['linkUrl']?.toString(),
      displayOrder:
          (json['displayOrder'] is num)
              ? (json['displayOrder'] as num).toInt()
              : 0,
      isActive: json['isActive'] == true,
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
    );
  }

  static List<AdminBanner> listFrom(dynamic data) {
    if (data is! List<dynamic>) return const [];
    return [
      for (final row in data)
        if (row is Map<String, dynamic>) fromJson(row),
    ];
  }
}
