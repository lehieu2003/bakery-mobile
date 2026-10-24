import 'package:bakery_mobile/src/core/network/api_client.dart';

/// Datasource over `/api/admin/pages`.
class PageAdminApiService {
  const PageAdminApiService(this._client);

  final ApiClient _client;

  Future<dynamic> getPages() => _client.get('/api/admin/pages');

  Future<Map<String, dynamic>> createPage(Map<String, dynamic> body) async {
    final r = await _client.post('/api/admin/pages', body: body);
    return r is Map<String, dynamic> ? r : const {};
  }

  Future<Map<String, dynamic>> updatePage(
    String id,
    Map<String, dynamic> body,
  ) async {
    final r = await _client.put('/api/admin/pages/$id', body: body);
    return r is Map<String, dynamic> ? r : const {};
  }

  Future<void> deletePage(String id) async {
    await _client.delete('/api/admin/pages/$id');
  }
}
