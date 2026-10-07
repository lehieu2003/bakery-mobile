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
    this.comparePrice,
    this.imageUrl,
    this.description,
    this.shortDescription,
    this.images = const [],
    this.variants = const [],
    this.ratingAverage,
    this.reviewCount,
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
  final List<ProductImageDto> images;
  final List<ProductVariantDto> variants;

  /// Review stats attached by the public product detail route
  /// (`ratingAverage` rounded to 1 decimal, `reviewCount` total); null when
  /// the payload omits them.
  final double? ratingAverage;
  final int? reviewCount;

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'] as List<dynamic>? ?? const [];
    final rawVariants = json['variants'] as List<dynamic>? ?? const [];
    return ProductDto(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      price: ParseUtils.toDouble(json['price'], field: 'ProductDto.price'),
      comparePrice: json['comparePrice'] == null
          ? null
          : ParseUtils.toDouble(
              json['comparePrice'],
              field: 'ProductDto.comparePrice',
            ),
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
      ratingAverage: _toDoubleOrNull(json['ratingAverage']),
      reviewCount: json['reviewCount'] == null
          ? null
          : ParseUtils.toInt(json['reviewCount'], field: 'ProductDto.reviewCount'),
    );
  }

  Product toDomain() => Product(
    id: id,
    name: name,
    slug: slug,
    price: price,
    comparePrice: comparePrice,
    stock: stock,
    imageUrl: imageUrl,
    description: description,
    shortDescription: shortDescription,
    images: images.map((e) => e.toDomain()).toList(),
    variants: variants.map((e) => e.toDomain()).toList(),
    ratingAverage: ratingAverage,
    reviewCount: reviewCount,
  );
}

double? _toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
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

class ProductFiltersDto {
  const ProductFiltersDto({
    required this.groups,
    required this.minPrice,
    required this.maxPrice,
  });

  final List<ProductFilterGroupDto> groups;
  final double minPrice;
  final double maxPrice;

  factory ProductFiltersDto.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['filters'] as List<dynamic>? ?? const [];
    final priceRange = json['priceRange'] as Map<String, dynamic>? ?? const {};
    return ProductFiltersDto(
      groups: rawGroups
          .whereType<Map<String, dynamic>>()
          .map(ProductFilterGroupDto.fromJson)
          .toList(),
      minPrice: ParseUtils.toDouble(
        priceRange['min'],
        field: 'ProductFiltersDto.minPrice',
      ),
      maxPrice: ParseUtils.toDouble(
        priceRange['max'],
        field: 'ProductFiltersDto.maxPrice',
      ),
    );
  }

  ProductFilters toDomain() {
    return ProductFilters(
      groups: groups.map((e) => e.toDomain()).toList(),
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }
}

class ProductFilterGroupDto {
  const ProductFilterGroupDto({
    required this.id,
    required this.name,
    required this.slug,
    this.values = const [],
  });

  final String id;
  final String name;
  final String slug;
  final List<ProductFilterValueDto> values;

  factory ProductFilterGroupDto.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'] as List<dynamic>? ?? const [];
    return ProductFilterGroupDto(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      values: rawValues
          .whereType<Map<String, dynamic>>()
          .map(ProductFilterValueDto.fromJson)
          .toList(),
    );
  }

  ProductFilterGroup toDomain() {
    return ProductFilterGroup(
      id: id,
      name: name,
      slug: slug,
      values: values.map((e) => e.toDomain()).toList(),
    );
  }
}

class ProductFilterValueDto {
  const ProductFilterValueDto({
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

  factory ProductFilterValueDto.fromJson(Map<String, dynamic> json) {
    return ProductFilterValueDto(
      id: (json['id'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      label: (json['label'] ?? json['value'] ?? '').toString(),
      colorHex: json['colorHex']?.toString(),
      productCount: ParseUtils.toInt(
        json['productCount'],
        field: 'ProductFilterValueDto.productCount',
      ),
    );
  }

  ProductFilterValue toDomain() {
    return ProductFilterValue(
      id: id,
      slug: slug,
      label: label,
      colorHex: colorHex,
      productCount: productCount,
    );
  }
}
