class AppPageSummary {
  const AppPageSummary({
    required this.id,
    required this.title,
    required this.slug,
  });

  final String id;
  final String title;
  final String slug;

  factory AppPageSummary.fromJson(Map<String, dynamic> json) {
    return AppPageSummary(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
    );
  }
}

class AppPageDetail {
  const AppPageDetail({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
  });

  final String id;
  final String title;
  final String slug;
  final String content;

  factory AppPageDetail.fromJson(Map<String, dynamic> json) {
    return AppPageDetail(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
    );
  }
}

