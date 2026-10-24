import 'package:bakery_mobile/src/features/admin/products/domain/models/admin_product.dart';
import 'package:bakery_mobile/src/features/admin/shared/utils/json_num.dart';

/// Parses an admin product list row into the [AdminProductListItem] domain
/// model. Every field is read defensively: Decimal money fields arrive as
/// numeric strings (`price`, `comparePrice`), `comparePrice` may be null,
/// `images` may be empty (no thumbnail) and categories arrive as m2m join
/// rows `{ categoryId, category }` — the first row's category names the
/// product and every row feeds [AdminProductListItem.categoryIds]. Variant
/// contents are ignored (list rows only need their existence).
class AdminProductDto {
  const AdminProductDto._();

  static AdminProductListItem fromJson(Map<String, dynamic> json) {
    String? categoryName;
    final categoryIds = <String>[];
    for (final link in _parseCategoryLinks(json)) {
      categoryIds.add(link.categoryId);
      categoryName ??= link.categoryName;
    }
    return AdminProductListItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      price: asNum(json['price']).toDouble(),
      comparePrice: json['comparePrice'] == null
          ? null
          : asNum(json['comparePrice']).toDouble(),
      stock: asNum(json['stock']).toInt(),
      isActive: json['isActive'] == true,
      thumbnailUrl: _thumbnailFrom(json['images']),
      categoryName: categoryName,
      categoryIds: categoryIds,
    );
  }

  /// Thumbnail is `images[0].url` — the server orders the list by
  /// displayOrder ascending, so the first entry is the primary image.
  static String? _thumbnailFrom(dynamic images) {
    if (images is List<dynamic> && images.isNotEmpty) {
      final first = images.first;
      if (first is Map<String, dynamic>) {
        final url = first['url']?.toString();
        if (url != null && url.isNotEmpty) return url;
      }
    }
    return null;
  }

  /// Flattens the m2m `categories` join rows into (id, name) links,
  /// skipping malformed entries. Falls back to the flat `category` alias
  /// when no join rows are present.
  static Iterable<({String categoryId, String? categoryName})>
  _parseCategoryLinks(Map<String, dynamic> json) sync* {
    var linked = false;
    final rows = json['categories'];
    if (rows is List<dynamic>) {
      for (final row in rows) {
        if (row is! Map<String, dynamic>) continue;
        final nested = row['category'];
        final id =
            row['categoryId']?.toString() ??
            (nested is Map<String, dynamic> ? nested['id']?.toString() : null);
        if (id == null || id.isEmpty) continue;
        linked = true;
        yield (
          categoryId: id,
          categoryName: nested is Map<String, dynamic>
              ? nested['name']?.toString()
              : null,
        );
      }
    }
    if (linked) return;

    // Flat alias shape (`category` object instead of join rows).
    final category = json['category'];
    if (category is Map<String, dynamic>) {
      final id = category['id']?.toString();
      if (id != null && id.isNotEmpty) {
        yield (categoryId: id, categoryName: category['name']?.toString());
      }
    }
  }
}

// ─────────────────── Phase 4b: detail + catalogue parsing ───────────────────

/// Parses `GET /api/admin/products/{id}` — the payload is wrapped as
/// `data.product` (unlike the customers detail, which is bare).
class AdminProductDetailDto {
  const AdminProductDetailDto._();

  static AdminProductDetail fromJson(Map<String, dynamic> data) {
    final product = data['product'] is Map<String, dynamic>
        ? data['product']! as Map<String, dynamic>
        : const <String, dynamic>{};
    return AdminProductDetail(
      id: (product['id'] ?? '').toString(),
      name: (product['name'] ?? '').toString(),
      slug: (product['slug'] ?? '').toString(),
      price: asNum(product['price']).toDouble(),
      comparePrice: product['comparePrice'] == null
          ? null
          : asNum(product['comparePrice']).toDouble(),
      stock: asNum(product['stock']).toInt(),
      isActive: product['isActive'] == true,
      isFeatured: product['isFeatured'] == true,
      shortDescription: product['shortDescription']?.toString(),
      description: product['description']?.toString(),
      images: _parseDetailImages(product['images']),
      variants: _parseDetailVariants(product['variants']),
      categoryIds: _parseDetailCategoryIds(product),
      assignments: _parseAssignments(product['attributeAssignments']),
    );
  }

  /// Reuses the list DTO's m2m join-row parsing for the id list.
  static List<String> _parseDetailCategoryIds(Map<String, dynamic> product) {
    return AdminProductDto.fromJson(product).categoryIds;
  }

  static List<AdminProductImage> _parseDetailImages(dynamic rows) {
    if (rows is! List<dynamic>) return const [];
    return [
      for (final row in rows)
        if (row is Map<String, dynamic>)
          AdminProductImage(
            id: row['id']?.toString(),
            url: (row['url'] ?? '').toString(),
            isPrimary: row['isPrimary'] == true,
          ),
    ];
  }

  static List<AdminProductVariant> _parseDetailVariants(dynamic rows) {
    if (rows is! List<dynamic>) return const [];
    return [
      for (final row in rows)
        if (row is Map<String, dynamic>)
          AdminProductVariant(
            id: row['id']?.toString(),
            name: (row['name'] ?? '').toString(),
            sku: row['sku']?.toString(),
            price: asNum(row['price']).toDouble(),
            stock: asNum(row['stock']).toInt(),
          ),
    ];
  }

  /// The server stores one row PER VALUE (`{attributeId, valueId}`); the
  /// form wants them grouped per attribute. Grouped wire rows
  /// (`{attributeId, valueIds}`) pass through unchanged.
  static List<AdminProductDetailAssignment> _parseAssignments(dynamic rows) {
    if (rows is! List<dynamic>) return const [];
    final grouped = <String, Set<String>>{};
    final orderedAttributes = <String>[];
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final attributeId = (row['attributeId'] ?? '').toString();
      if (attributeId.isEmpty) continue;
      final values = grouped.putIfAbsent(attributeId, () => <String>{});
      if (!orderedAttributes.contains(attributeId)) {
        orderedAttributes.add(attributeId);
      }
      values.addAll(_stringList(row['valueIds']));
      final single = row['valueId']?.toString();
      if (single != null && single.isNotEmpty) values.add(single);
    }
    return [
      for (final id in orderedAttributes)
        AdminProductDetailAssignment(
          attributeId: id,
          valueIds: grouped[id]!.toList(),
        ),
    ];
  }
}

/// Parses `GET /api/admin/product-attributes` — `{attributes: [...]}` or a
/// bare array, both accepted.
class ProductAttributeCatalogueDto {
  const ProductAttributeCatalogueDto._();

  static List<AdminAttribute> fromJson(Map<String, dynamic> data) {
    final rows = data['attributes'] is List<dynamic>
        ? data['attributes']! as List<dynamic>
        : const <dynamic>[];
    return [
      for (final row in rows)
        if (row is Map<String, dynamic>)
          AdminAttribute(
            id: (row['id'] ?? '').toString(),
            name: (row['name'] ?? '').toString(),
            type: (row['type'] ?? '') == 'SELECT'
                ? AttributeType.select
                : AttributeType.multiSelect,
            values: _parseAttributeValues(row['values']),
          ),
    ];
  }

  static List<AdminAttributeValue> _parseAttributeValues(dynamic rows) {
    if (rows is! List<dynamic>) return const [];
    return [
      for (final row in rows)
        if (row is Map<String, dynamic>)
          AdminAttributeValue(
            id: (row['id'] ?? '').toString(),
            label: (row['label'] ?? row['value'] ?? '').toString(),
          ),
    ];
  }
}

List<String> _stringList(dynamic raw) {
  if (raw is List<dynamic>) {
    return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
  return const [];
}
