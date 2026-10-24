/// Admin header menu item (`GET /api/admin/menu` — bare array).
class AdminMenuItem {
  const AdminMenuItem({
    required this.id,
    required this.title,
    this.type = 'LINK',
    this.url,
    required this.displayOrder,
    required this.isActive,
  });

  final String id;
  final String title;

  /// `LINK` for now (server default).
  final String type;
  final String? url;
  final int displayOrder;
  final bool isActive;
}
