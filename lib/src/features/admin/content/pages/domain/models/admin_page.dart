/// Admin static page row (`GET /api/admin/pages` — bare array).
class AdminPage {
  const AdminPage({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    required this.isPublished,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String slug;

  /// Stored verbatim — newlines preserved.
  final String content;
  final bool isPublished;
  final DateTime createdAt;
}
