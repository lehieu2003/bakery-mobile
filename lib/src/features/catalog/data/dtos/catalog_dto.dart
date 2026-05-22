import 'package:bakery_mobile/src/features/catalog/domain/models/banner_item.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/category.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';
import 'package:bakery_mobile/src/core/utils/parse_utils.dart';

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
    this.imageUrl,
    this.description,
    this.children = const [],
  });

  final String id;
  final String name;
  final String slug;
  final String? imageUrl;
  final String? description;
  final List<CategoryDto> children;

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'] as List<dynamic>? ?? const [];
    return CategoryDto(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      imageUrl: json['imageUrl']?.toString(),
      description: json['description']?.toString(),
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
      imageUrl: imageUrl,
      description: description,
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
      price: ParseUtils.toDouble(
        json['price'],
        field: 'ProductVariantDto.price',
      ),
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
  final int stock;
  final String? imageUrl;
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
      price: ParseUtils.toDouble(json['price'], field: 'ProductDto.price'),
      stock: ParseUtils.toInt(json['stock'], field: 'ProductDto.stock'),
      imageUrl: json['imageUrl']?.toString(),
      description: json['description']?.toString(),
      shortDescription: json['shortDescription']?.toString(),
      images: rawImages
          .map((item) {
            if (item is String) {
              return ProductImageDto(url: item, isPrimary: false);
            }
            if (item is Map<String, dynamic>) {
              return ProductImageDto.fromJson(item);
            }
            return null;
          })
          .whereType<ProductImageDto>()
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
    imageUrl: imageUrl,
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

class PersonalizedProductsDto {
  const PersonalizedProductsDto({
    required this.products,
    required this.source,
    required this.reason,
  });

  final List<ProductDto> products;
  final String source;
  final String reason;

  factory PersonalizedProductsDto.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'] as List<dynamic>? ?? const [];
    return PersonalizedProductsDto(
      products: rawProducts
          .whereType<Map<String, dynamic>>()
          .map(ProductDto.fromJson)
          .toList(),
      source: (json['source'] ?? 'fallback').toString(),
      reason: (json['reason'] ?? 'no-signal').toString(),
    );
  }
}
