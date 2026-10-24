import 'package:bakery_mobile/src/features/admin/categories/data/datasources/category_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/categories/data/dtos/category_admin_dto.dart';
import 'package:bakery_mobile/src/features/admin/categories/domain/models/admin_category.dart';

/// Admin category repository: tree read, CRUD and root reorder over
/// `/api/admin/categories`. Errors (e.g. deleting a category that still
/// has children/products) bubble up untouched so the view model can show
/// the server's message.
class CategoryAdminRepository {
  const CategoryAdminRepository(this._service);

  final CategoryAdminApiService _service;

  /// Loads the full category tree (roots with nested children).
  Future<List<AdminCategoryNode>> getCategories() async {
    return CategoryAdminDto.fromEnvelope(await _service.getCategories());
  }

  /// Creates a category; [slug] and [parentId] are optional. Returns the
  /// created node (children always empty — a new category has none).
  Future<AdminCategoryNode> createCategory({
    required String name,
    String? slug,
    String? parentId,
  }) async {
    return CategoryAdminDto.fromMutationEnvelope(
      await _service.createCategory(name: name, slug: slug, parentId: parentId),
    );
  }

  /// Updates a category; only provided keys are sent. Returns the updated
  /// node with its children.
  Future<AdminCategoryNode> updateCategory(
    String id, {
    String? name,
    String? slug,
    String? parentId,
  }) async {
    return CategoryAdminDto.fromMutationEnvelope(
      await _service.updateCategory(
        id,
        name: name,
        slug: slug,
        parentId: parentId,
      ),
    );
  }

  /// Deletes a category by id. Server refusals ("Cannot delete category
  /// with N products/child categories") propagate with the message intact.
  Future<void> deleteCategory(String id) async {
    await _service.deleteCategory(id);
  }

  /// Persists a new order for the root categories ([orderedIds] in their
  /// new display order).
  Future<void> reorderCategories(List<String> orderedIds) async {
    await _service.reorderCategories(orderedIds);
  }
}
