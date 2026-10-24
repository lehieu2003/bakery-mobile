/// Admin view of a product list row as exposed by
/// `GET /api/admin/products`. Money fields are doubles (the server emits
/// Prisma Decimals as numeric strings); `thumbnailUrl`/`categoryName` are
/// null when the product has no images/categories.
class AdminProductListItem {
  const AdminProductListItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    this.comparePrice,
    required this.stock,
    required this.isActive,
    this.thumbnailUrl,
    this.categoryName,
    this.categoryIds = const [],
  });

  final String id;
  final String name;
  final String slug;

  /// Current selling price in VND.
  final double price;

  /// Crossed-out pre-sale price; null when the product is not on sale.
  final double? comparePrice;

  final int stock;
  final bool isActive;

  /// First image url (the server orders images by displayOrder); null when
  /// the product has no images.
  final String? thumbnailUrl;

  /// Name of the product's first category; null when uncategorized.
  final String? categoryName;

  /// Ids of every category linked to the product (m2m).
  final List<String> categoryIds;
}

// ─────────────────── Phase 4b: product form domain ───────────────────

/// Full admin product payload for the form (GET/POST/PUT
/// `/api/admin/products/{id}`). Money fields are doubles (server Decimals
/// arrive as strings and are coerced).
class AdminProductDetail {
  const AdminProductDetail({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    this.comparePrice,
    required this.stock,
    required this.isActive,
    required this.isFeatured,
    this.shortDescription,
    this.description,
    this.images = const [],
    this.variants = const [],
    this.categoryIds = const [],
    this.assignments = const [],
  });

  final String id;
  final String name;
  final String slug;
  final double price;
  final double? comparePrice;
  final int stock;
  final bool isActive;
  final bool isFeatured;
  final String? shortDescription;
  final String? description;
  final List<AdminProductImage> images;
  final List<AdminProductVariant> variants;
  final List<String> categoryIds;

  /// Attribute picks grouped per attribute (per-value server rows merged).
  final List<AdminProductDetailAssignment> assignments;
}

/// One stored image of a product.
class AdminProductImage {
  const AdminProductImage({this.id, required this.url, this.isPrimary = false});

  final String? id;
  final String url;
  final bool isPrimary;
}

/// One dynamic variant row.
class AdminProductVariant {
  const AdminProductVariant({
    this.id,
    required this.name,
    this.sku,
    required this.price,
    required this.stock,
  });

  final String? id;
  final String name;
  final String? sku;
  final double price;
  final int stock;
}

/// Attribute → chosen values for one product.
class AdminProductDetailAssignment {
  const AdminProductDetailAssignment({
    required this.attributeId,
    this.valueIds = const [],
  });

  final String attributeId;
  final List<String> valueIds;

  /// Accepts BOTH wire shapes: grouped `{attributeId, valueIds}` (what
  /// POST/PUT sends) and the per-value storage rows merged upstream.
  factory AdminProductDetailAssignment.fromJson(Map<String, dynamic> json) {
    return AdminProductDetailAssignment(
      attributeId: (json['attributeId'] ?? '').toString(),
      valueIds: _stringList(json['valueIds']),
    );
  }
}

/// One filterable attribute of the catalogue (`GET
/// /api/admin/product-attributes`) with its pickable values.
class AdminAttribute {
  const AdminAttribute({
    required this.id,
    required this.name,
    required this.type,
    this.values = const [],
  });

  final String id;
  final String name;
  final AttributeType type;
  final List<AdminAttributeValue> values;
}

enum AttributeType { select, multiSelect }

class AdminAttributeValue {
  const AdminAttributeValue({required this.id, required this.label});

  final String id;
  final String label;
}

List<String> _stringList(dynamic raw) {
  if (raw is List<dynamic>) {
    return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
  return const [];
}
