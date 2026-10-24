/// Admin blog post list row.
class BlogPost {
  const BlogPost({
    required this.id,
    required this.title,
    required this.slug,
    this.excerpt,
    required this.status,
    this.coverUrl,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String slug;
  final String? excerpt;

  /// `DRAFT` | `PUBLISHED` (server enum).
  final String status;
  final String? coverUrl;
  final DateTime createdAt;
}

/// Blog category row.
class BlogCategory {
  const BlogCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String slug;
  final bool isActive;
}

/// Blog tag row.
class BlogTag {
  const BlogTag({required this.id, required this.name, required this.slug});

  final String id;
  final String name;
  final String slug;
}

String blogStatusFrom(String raw) => raw; // DRAFT/PUBLISHED verbatim

String blogStatusLabel(String status) =>
    status == 'PUBLISHED' ? 'Đã đăng' : 'Bản nháp';
