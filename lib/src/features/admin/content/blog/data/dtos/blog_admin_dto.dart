import 'package:bakery_mobile/src/features/admin/content/blog/domain/models/blog_models.dart';

/// Parses the `{posts, pagination}` list envelope.
class BlogPostListDto {
  const BlogPostListDto._();

  static BlogPostPage fromJson(Map<String, dynamic> data) {
    final rows = data['posts'];
    final pagination = data['pagination'];
    return BlogPostPage(
      items: rows is List<dynamic>
          ? [
              for (final row in rows)
                if (row is Map<String, dynamic>)
                  BlogPost(
                    id: (row['id'] ?? '').toString(),
                    title: (row['title'] ?? '').toString(),
                    slug: (row['slug'] ?? '').toString(),
                    excerpt: row['excerpt']?.toString(),
                    status: (row['status'] ?? 'DRAFT').toString(),
                    coverUrl: row['coverUrl']?.toString(),
                    createdAt:
                        DateTime.tryParse('${row['createdAt'] ?? ''}') ??
                        DateTime.now(),
                  ),
            ]
          : const [],
      total: pagination is Map<String, dynamic> &&
              pagination['total'] is num
          ? (pagination['total'] as num).toInt()
          : 0,
      totalPages: pagination is Map<String, dynamic> &&
              pagination['totalPages'] is num
          ? (pagination['totalPages'] as num).toInt()
          : 1,
    );
  }
}

class BlogPostPage {
  const BlogPostPage({
    required this.items,
    required this.total,
    required this.totalPages,
  });

  final List<BlogPost> items;
  final int total;
  final int totalPages;
}

BlogCategory blogCategoryFromJson(Map<String, dynamic> json) => BlogCategory(
  id: (json['id'] ?? '').toString(),
  name: (json['name'] ?? '').toString(),
  slug: (json['slug'] ?? '').toString(),
  isActive: json['isActive'] == true,
);

BlogTag blogTagFromJson(Map<String, dynamic> json) => BlogTag(
  id: (json['id'] ?? '').toString(),
  name: (json['name'] ?? '').toString(),
  slug: (json['slug'] ?? '').toString(),
);

List<BlogCategory> blogCategoryListFrom(dynamic data) {
  final rows = data is Map<String, dynamic> ? data['categories'] : data;
  if (rows is! List<dynamic>) return const [];
  return [
    for (final row in rows)
      if (row is Map<String, dynamic>) blogCategoryFromJson(row),
  ];
}

List<BlogTag> blogTagListFrom(dynamic data) {
  final rows = data is Map<String, dynamic> ? data['tags'] : data;
  if (rows is! List<dynamic>) return const [];
  return [
    for (final row in rows)
      if (row is Map<String, dynamic>) blogTagFromJson(row),
  ];
}
