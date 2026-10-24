import 'package:bakery_mobile/src/core/network/api_client.dart';

/// Datasource over `/api/admin/blog/**`.
class BlogAdminApiService {
  const BlogAdminApiService(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> getPosts({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final r = await _client.get(
      '/api/admin/blog/posts',
      query: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return r is Map<String, dynamic> ? r : const {};
  }

  Future<Map<String, dynamic>> createPost(Map<String, dynamic> body) async {
    final r = await _client.post('/api/admin/blog/posts', body: body);
    return r is Map<String, dynamic> ? r : const {};
  }

  Future<void> updatePostStatus(String id, String status) async {
    await _client.patch(
      '/api/admin/blog/posts/$id/status',
      body: {'status': status},
    );
  }

  Future<void> deletePost(String id) async {
    await _client.delete('/api/admin/blog/posts/$id');
  }

  Future<dynamic> getCategories() => _client.get('/api/admin/blog/categories');

  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> body) async {
    final r = await _client.post('/api/admin/blog/categories', body: body);
    return r is Map<String, dynamic> ? r : const {};
  }

  Future<void> deleteCategory(String id) async {
    await _client.delete('/api/admin/blog/categories/$id');
  }

  Future<dynamic> getTags() => _client.get('/api/admin/blog/tags');

  Future<Map<String, dynamic>> createTag(Map<String, dynamic> body) async {
    final r = await _client.post('/api/admin/blog/tags', body: body);
    return r is Map<String, dynamic> ? r : const {};
  }

  Future<void> deleteTag(String id) async {
    await _client.delete('/api/admin/blog/tags/$id');
  }
}
