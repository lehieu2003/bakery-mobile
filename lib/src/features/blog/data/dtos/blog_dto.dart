import 'package:bakery_mobile/src/features/blog/domain/models/blog.dart';

class BlogCategoryDto {
  const BlogCategoryDto({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory BlogCategoryDto.fromJson(Map<String, dynamic> json) {
    return BlogCategoryDto(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
    );
  }

  BlogCategory toDomain() => BlogCategory(id: id, name: name, slug: slug);
}

class BlogTagDto {
  const BlogTagDto({required this.id, required this.name, required this.slug});

  final String id;
  final String name;
  final String slug;

  factory BlogTagDto.fromJson(Map<String, dynamic> json) {
    return BlogTagDto(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
    );
  }

  BlogTag toDomain() => BlogTag(id: id, name: name, slug: slug);
}

class BlogPostDto {
  const BlogPostDto({
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
  final BlogCategoryDto? category;
  final List<BlogTagDto> tags;

  factory BlogPostDto.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'] as List<dynamic>? ?? const [];
    return BlogPostDto(
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
          ? BlogCategoryDto.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      tags: rawTags
          .whereType<Map<String, dynamic>>()
          .map(BlogTagDto.fromJson)
          .toList(),
    );
  }

  BlogPost toDomain() {
    return BlogPost(
      id: id,
      title: title,
      slug: slug,
      excerpt: excerpt,
      content: content,
      coverUrl: coverUrl,
      viewCount: viewCount,
      publishedAt: publishedAt,
      category: category?.toDomain(),
      tags: tags.map((e) => e.toDomain()).toList(),
    );
  }
}

class BlogListResultDto {
  const BlogListResultDto({
    required this.posts,
    required this.page,
    required this.totalPages,
  });

  final List<BlogPostDto> posts;
  final int page;
  final int totalPages;
}
