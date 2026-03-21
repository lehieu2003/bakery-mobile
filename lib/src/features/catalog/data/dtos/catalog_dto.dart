import 'package:bakery_mobile/src/features/catalog/domain/models/banner_item.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/category.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';

class BannerItemDto {
  const BannerItemDto({
    required this.id,
    required this.title,
    this.imageUrl,
    this.linkUrl,
    required this.isActive,
  });

  final String id;
  final String title;
  final String? imageUrl;
  final String? linkUrl;
  final bool isActive;

  factory BannerItemDto.fromJson(Map<String, dynamic> json) {
    return BannerItemDto(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      imageUrl: json['imageUrl']?.toString(),
      linkUrl: json['linkUrl']?.toString(),
      isActive: json['isActive'] == true,
    );
  }

  BannerItem toDomain() => BannerItem(
    id: id,
    title: title,
    imageUrl: imageUrl,
    linkUrl: linkUrl,
    isActive: isActive,
  );
}

class CategoryDto {
  const CategoryDto({
    required this.id,
    required this.name,
    required this.slug,
    this.children = const [],
  });

  final String id;
  final String name;
  final String slug;
  final List<CategoryDto> children;

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'] as List<dynamic>? ?? const [];
    return CategoryDto(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      children: rawChildren
          .whereType<Map<String, dynamic>>()
          .map(CategoryDto.fromJson)
          .toList(),
    );
  }

  Category toDomain() {
    return Category(
      id: id,
      name: name,
      slug: slug,
      children: children.map((e) => e.toDomain()).toList(),
    );
  }
}

class ProductImageDto {
  const ProductImageDto({required this.url, required this.isPrimary});

  final String url;
  final bool isPrimary;

  factory ProductImageDto.fromJson(Map<String, dynamic> json) {
    return ProductImageDto(
      url: (json['url'] ?? '').toString(),
      isPrimary: json['isPrimary'] == true,
    );
  }

  ProductImage toDomain() => ProductImage(url: url, isPrimary: isPrimary);
}

class ProductVariantDto {
  const ProductVariantDto({
    required this.id,
    required this.name,
    required this.price,
  });

  final String id;
  final String name;
  final double price;

  factory ProductVariantDto.fromJson(Map<String, dynamic> json) {
    return ProductVariantDto(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }

  ProductVariant toDomain() => ProductVariant(id: id, name: name, price: price);
}

class ProductDto {
  const ProductDto({
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
  final List<ProductImageDto> images;
  final List<ProductVariantDto> variants;

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'] as List<dynamic>? ?? const [];
    final rawVariants = json['variants'] as List<dynamic>? ?? const [];
    return ProductDto(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stock: json['stock'] is int
          ? json['stock'] as int
          : int.tryParse('${json['stock'] ?? ''}') ?? 0,
      description: json['description']?.toString(),
      shortDescription: json['shortDescription']?.toString(),
      images: rawImages
          .whereType<Map<String, dynamic>>()
          .map(ProductImageDto.fromJson)
          .toList(),
      variants: rawVariants
          .whereType<Map<String, dynamic>>()
          .map(ProductVariantDto.fromJson)
          .toList(),
    );
  }

  Product toDomain() => Product(
    id: id,
    name: name,
    slug: slug,
    price: price,
    stock: stock,
    description: description,
    shortDescription: shortDescription,
    images: images.map((e) => e.toDomain()).toList(),
    variants: variants.map((e) => e.toDomain()).toList(),
  );
}

class ProductListResultDto {
  const ProductListResultDto({required this.products, required this.total});

  final List<ProductDto> products;
  final int total;
}
