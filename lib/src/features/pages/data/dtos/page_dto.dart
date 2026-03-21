import 'package:bakery_mobile/src/features/pages/domain/models/app_page.dart';

class AppPageSummaryDto {
  const AppPageSummaryDto({
    required this.id,
    required this.title,
    required this.slug,
  });

  final String id;
  final String title;
  final String slug;

  factory AppPageSummaryDto.fromJson(Map<String, dynamic> json) {
    return AppPageSummaryDto(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
    );
  }

  AppPageSummary toDomain() => AppPageSummary(id: id, title: title, slug: slug);
}

class AppPageDetailDto {
  const AppPageDetailDto({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
  });

  final String id;
  final String title;
  final String slug;
  final String content;

  factory AppPageDetailDto.fromJson(Map<String, dynamic> json) {
    return AppPageDetailDto(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
    );
  }

  AppPageDetail toDomain() {
    return AppPageDetail(id: id, title: title, slug: slug, content: content);
  }
}
