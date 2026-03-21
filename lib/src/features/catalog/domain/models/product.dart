class ProductImage {
  const ProductImage({required this.url, required this.isPrimary});

  final String url;
  final bool isPrimary;

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      url: (json['url'] ?? '').toString(),
      isPrimary: json['isPrimary'] == true,
    );
  }
}

class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.name,
    required this.price,
  });

  final String id;
  final String name;
  final double price;

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    required this.stock,
    this.description,
    this.shortDescription,
    this.images = const [],
    this.variants = const [],
  });

  final String id;
  final String name;
  final String slug;
  final double price;
  final int stock;
  final String? description;
  final String? shortDescription;
  final List<ProductImage> images;
  final List<ProductVariant> variants;

  String get thumbnail {
    final primary = images.where((image) => image.isPrimary).toList();
    if (primary.isNotEmpty) return primary.first.url;
    if (images.isNotEmpty) return images.first.url;
    return '';
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>? ?? const [];
    final variants = json['variants'] as List<dynamic>? ?? const [];

    return Product(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stock: json['stock'] is int
          ? json['stock'] as int
          : int.tryParse('${json['stock'] ?? ''}') ?? 0,
      description: json['description']?.toString(),
      shortDescription: json['shortDescription']?.toString(),
      images: images
          .whereType<Map<String, dynamic>>()
          .map(ProductImage.fromJson)
          .toList(),
      variants: variants
          .whereType<Map<String, dynamic>>()
          .map(ProductVariant.fromJson)
          .toList(),
    );
  }
}

