import 'package:bakery_mobile/src/core/network/api_client.dart';

/// Datasource over `/api/admin/menu`.
class MenuAdminApiService {
  const MenuAdminApiService(this._client);

  final ApiClient _client;

  Future<dynamic> getMenu() => _client.get('/api/admin/menu');

  Future<Map<String, dynamic>> createMenuItem(Map<String, dynamic> body) async {
    final r = await _client.post('/api/admin/menu', body: body);
    return r is Map<String, dynamic> ? r : const {};
  }

  Future<Map<String, dynamic>> updateMenuItem(
    String id,
    Map<String, dynamic> body,
  ) async {
    final r = await _client.put('/api/admin/menu/$id', body: body);
    return r is Map<String, dynamic> ? r : const {};
  }

  Future<void> deleteMenuItem(String id) async {
    await _client.delete('/api/admin/menu/$id');
  }
}
