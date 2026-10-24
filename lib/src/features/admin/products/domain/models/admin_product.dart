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
