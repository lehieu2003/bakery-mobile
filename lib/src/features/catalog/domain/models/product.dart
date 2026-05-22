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
    this.comparePrice,
    this.imageUrl,
    this.description,
    this.shortDescription,
    this.images = const [],
    this.variants = const [],
  });

  final String id;
  final String name;
  final String slug;
  final double price;
  final double? comparePrice;
  final int stock;
  final String? imageUrl;
  final String? description;
  final String? shortDescription;
  final List<ProductImage> images;
  final List<ProductVariant> variants;

  String get thumbnail {
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl!;
    final primary = images.where((image) => image.isPrimary).toList();
    if (primary.isNotEmpty) return primary.first.url;
    if (images.isNotEmpty) return images.first.url;
    return '';
  }

  bool get hasDiscount {
    final original = comparePrice;
    return original != null && original > price;
  }

  int? get discountPercent {
    final original = comparePrice;
    if (original == null || original <= price || original <= 0) return null;
    return ((1 - price / original) * 100).round();
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>? ?? const [];
    final variants = json['variants'] as List<dynamic>? ?? const [];

    return Product(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      comparePrice: _toDoubleOrNull(json['comparePrice']),
      stock: json['stock'] is int
          ? json['stock'] as int
          : int.tryParse('${json['stock'] ?? ''}') ?? 0,
      imageUrl: json['imageUrl']?.toString(),
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

double? _toDoubleOrNull(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

class ProductAttributeFilter {
  const ProductAttributeFilter({
    required this.attributeSlug,
    required this.valueSlugs,
  });

  final String attributeSlug;
  final List<String> valueSlugs;
}

class ProductFilters {
  const ProductFilters({
    this.groups = const [],
    this.minPrice = 0,
    this.maxPrice = 0,
  });

  final List<ProductFilterGroup> groups;
  final double minPrice;
  final double maxPrice;
}

class ProductFilterGroup {
  const ProductFilterGroup({
    required this.id,
    required this.name,
    required this.slug,
    this.values = const [],
  });

  final String id;
  final String name;
  final String slug;
  final List<ProductFilterValue> values;
}

class ProductFilterValue {
  const ProductFilterValue({
    required this.id,
    required this.slug,
    required this.label,
    required this.productCount,
    this.colorHex,
  });

  final String id;
  final String slug;
  final String label;
  final int productCount;
  final String? colorHex;
}
