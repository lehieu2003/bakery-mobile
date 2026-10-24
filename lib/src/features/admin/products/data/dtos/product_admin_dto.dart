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
