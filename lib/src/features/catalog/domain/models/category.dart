class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    this.description,
    this.children = const [],
  });

  final String id;
  final String name;
  final String slug;
  final String? imageUrl;
  final String? description;
  final List<Category> children;

  factory Category.fromJson(Map<String, dynamic> json) {
    final children = json['children'] as List<dynamic>? ?? const [];
    return Category(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      imageUrl: json['imageUrl']?.toString(),
      description: json['description']?.toString(),
      children: children
          .whereType<Map<String, dynamic>>()
          .map(Category.fromJson)
          .toList(),
    );
  }
}
