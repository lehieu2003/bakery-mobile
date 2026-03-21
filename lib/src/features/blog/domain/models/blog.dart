class BlogCategory {
  const BlogCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory BlogCategory.fromJson(Map<String, dynamic> json) {
    return BlogCategory(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
    );
  }
}

class BlogTag {
  const BlogTag({required this.id, required this.name, required this.slug});

  final String id;
  final String name;
  final String slug;

  factory BlogTag.fromJson(Map<String, dynamic> json) {
    return BlogTag(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
    );
  }
}

class BlogPost {
  const BlogPost({
    required this.id,
    required this.title,
    required this.slug,
    this.excerpt,
    this.content,
    this.coverUrl,
    this.viewCount = 0,
    this.publishedAt,
    this.category,
    this.tags = const [],
  });

  final String id;
  final String title;
  final String slug;
  final String? excerpt;
  final String? content;
  final String? coverUrl;
  final int viewCount;
  final DateTime? publishedAt;
  final BlogCategory? category;
  final List<BlogTag> tags;

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'] as List<dynamic>? ?? const [];
    return BlogPost(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      excerpt: json['excerpt']?.toString(),
      content: json['content']?.toString(),
      coverUrl: json['coverUrl']?.toString(),
      viewCount: json['viewCount'] is int
          ? json['viewCount'] as int
          : int.tryParse('${json['viewCount'] ?? ''}') ?? 0,
      publishedAt: DateTime.tryParse('${json['publishedAt'] ?? ''}'),
      category: json['category'] is Map<String, dynamic>
          ? BlogCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      tags: rawTags
          .whereType<Map<String, dynamic>>()
          .map(BlogTag.fromJson)
          .toList(),
    );
  }
}

class BlogListResult {
  const BlogListResult({
    required this.posts,
    required this.page,
    required this.totalPages,
  });

  final List<BlogPost> posts;
  final int page;
  final int totalPages;
}
