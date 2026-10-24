import 'package:bakery_mobile/src/core/network/api_client.dart';

/// CRUD on /api/admin/product-attributes — the filterable attribute
/// catalogue. `code` is required by the server on create; the repository
/// derives it so callers only need a display name.
class ProductAttributeAdminApiService {
  ProductAttributeAdminApiService(this._client);

  final ApiClient _client;

  Future<dynamic> getAttributes() async {
    return _client.get('/api/admin/product-attributes');
  }

  Future<dynamic> createAttribute(Map<String, dynamic> body) async {
    return _client.post('/api/admin/product-attributes', body: body);
  }

  Future<dynamic> updateAttribute(String id, Map<String, dynamic> body) async {
    return _client.put('/api/admin/product-attributes/$id', body: body);
  }

  Future<void> deleteAttribute(String id) async {
    await _client.delete('/api/admin/product-attributes/$id');
  }
}
