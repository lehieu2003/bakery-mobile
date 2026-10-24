/// Admin banner row (`GET /api/admin/banners` — bare array under `data`).
class AdminBanner {
  const AdminBanner({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.linkUrl,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? linkUrl;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
}
