import 'package:bakery_mobile/src/core/network/api_client.dart';

/// Thin datasource over `/api/admin/products`. Methods deal in raw JSON
/// maps so tests can substitute a fake [ApiClient] without knowing about
/// DTO parsing.
class ProductAdminApiService {
  const ProductAdminApiService(this._client);

  final ApiClient _client;

  /// GET /api/admin/products — paginated admin product list (newest
  /// first). [search] matches name / description server-side. Requires the
  /// ADMIN role. Returns `{ products: [...], pagination: {...} }`.
  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final response = await _client.get(
      '/api/admin/products',
      query: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return response as Map<String, dynamic>? ?? const {};
  }

  /// DELETE /api/admin/products/{id} — deletes a product (200 with a
  /// message envelope). A 404 (`Không tìm thấy sản phẩm`) or any other
  /// server refusal propagates as [ApiException] for the caller to show.
  Future<void> deleteProduct(String id) async {
    await _client.delete('/api/admin/products/$id');
  }

  /// GET /api/admin/products/{id} — full detail for the edit form. The
  /// payload wraps the product as `data.product` (kept raw here; the DTO
  /// unwraps).
  Future<Map<String, dynamic>> getProduct(String id) async {
    final response = await _client.get('/api/admin/products/\$id');
    return response is Map<String, dynamic> ? response : const {};
  }

  /// POST /api/admin/products — create. [body] is the pre-built payload
  /// (name required; price/stock numeric; images/variants/assignments per
  /// the web contract). Returns the raw created-product envelope.
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> body) async {
    final response = await _client.post('/api/admin/products', body: body);
    return response is Map<String, dynamic> ? response : const {};
  }

  /// PUT /api/admin/products/{id} — partial update; `images` and
  /// `attributeAssignments` replace their whole sets server-side.
  Future<Map<String, dynamic>> updateProduct(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.put('/api/admin/products/\$id', body: body);
    return response is Map<String, dynamic> ? response : const {};
  }

  /// GET /api/admin/product-attributes — the filterable attribute
  /// catalogue with values (for the form's attribute chips section).
  Future<dynamic> getAttributes() async {
    return _client.get('/api/admin/product-attributes');
  }
}
