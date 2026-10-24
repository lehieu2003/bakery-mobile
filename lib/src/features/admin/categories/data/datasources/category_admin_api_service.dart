import 'package:bakery_mobile/src/core/network/api_client.dart';

/// Thin datasource over `/api/admin/categories`. Methods deal in raw JSON
/// maps so tests can substitute a fake [ApiClient] without knowing about
/// DTO parsing.
class CategoryAdminApiService {
  const CategoryAdminApiService(this._client);

  final ApiClient _client;

  /// GET /api/admin/categories — the full category tree (roots with nested
  /// `children`, two levels deep, ordered by displayOrder). Requires the
  /// ADMIN role. Returns `{ categories: TREE }`.
  Future<Map<String, dynamic>> getCategories() async {
    final response = await _client.get('/api/admin/categories');
    return response as Map<String, dynamic>? ?? const {};
  }

  /// POST /api/admin/categories — creates a category; [slug] and
  /// [parentId] are optional (the server slugifies the name when [slug] is
  /// omitted). Only non-null keys are sent. Returns `{ category: {...} }`.
  Future<Map<String, dynamic>> createCategory({
    required String name,
    String? slug,
    String? parentId,
  }) async {
    final response = await _client.post(
      '/api/admin/categories',
      body: {
        'name': name,
        if (slug != null && slug.isNotEmpty) 'slug': slug,
        if (parentId != null && parentId.isNotEmpty) 'parentId': parentId,
      },
    );
    return response as Map<String, dynamic>? ?? const {};
  }

  /// PUT /api/admin/categories/{id} — updates a category. Only non-null
  /// keys are sent (name regenerates the slug server-side when slug is not
  /// given). Returns `{ category: {...} }`.
  Future<Map<String, dynamic>> updateCategory(
    String id, {
    String? name,
    String? slug,
    String? parentId,
  }) async {
    final response = await _client.put(
      '/api/admin/categories/$id',
      body: {
        if (name != null) 'name': name,
        if (slug != null) 'slug': slug,
        if (parentId != null) 'parentId': parentId,
      },
    );
    return response as Map<String, dynamic>? ?? const {};
  }

  /// DELETE /api/admin/categories/{id} — the server refuses (400) while
  /// the category still has children or products; the message propagates
  /// as [ApiException] for the caller to show.
  Future<void> deleteCategory(String id) async {
    await _client.delete('/api/admin/categories/$id');
  }

  /// PATCH /api/admin/categories/reorder — persists a new order for the
  /// root categories. The route expects `{ items: [{ id, displayOrder }] }`
  /// (an `orderedIds` body is rejected with "items array is required"), so
  /// [orderedIds] is mapped to items with displayOrder = list index.
  Future<void> reorderCategories(List<String> orderedIds) async {
    await _client.patch(
      '/api/admin/categories/reorder',
      body: {
        'items': [
          for (var i = 0; i < orderedIds.length; i++)
            {'id': orderedIds[i], 'displayOrder': i},
        ],
      },
    );
  }
}
