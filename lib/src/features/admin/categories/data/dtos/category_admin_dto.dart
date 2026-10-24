import 'package:bakery_mobile/src/features/admin/categories/domain/models/admin_category.dart';
import 'package:bakery_mobile/src/features/admin/shared/utils/json_num.dart';

/// Parses category payloads of `/api/admin/categories` into
/// [AdminCategoryNode]s. The list route returns a two-level tree; create
/// and update return a single `{ category: {...} }` node (without
/// children). Extra Prisma fields (`parentId`, `displayOrder`, `_count`,
/// ...) are tolerated and ignored.
class CategoryAdminDto {
  const CategoryAdminDto._();

  /// Parses one tree node, recursing into `children` (leaves carry an
  /// empty list).
  static AdminCategoryNode fromJson(Map<String, dynamic> json) {
    return AdminCategoryNode(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      children: parseJsonList(json['children'], CategoryAdminDto.fromJson),
    );
  }

  /// Parses the `{ categories: TREE }` envelope of
  /// `GET /api/admin/categories` into the root nodes (children nested).
  static List<AdminCategoryNode> fromEnvelope(Map<String, dynamic> json) {
    return parseJsonList(json['categories'], CategoryAdminDto.fromJson);
  }

  /// Parses the `{ category: {...} }` envelope of
  /// `POST /api/admin/categories` and `PUT /api/admin/categories/{id}`.
  static AdminCategoryNode fromMutationEnvelope(Map<String, dynamic> json) {
    final category = json['category'];
    if (category is Map<String, dynamic>) {
      return fromJson(category);
    }
    return fromJson(json);
  }
}
