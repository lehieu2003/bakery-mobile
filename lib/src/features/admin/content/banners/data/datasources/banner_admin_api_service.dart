import 'package:bakery_mobile/src/core/network/api_client.dart';

/// Datasource over `/api/admin/banners`.
class BannerAdminApiService {
  const BannerAdminApiService(this._client);

  final ApiClient _client;

  /// Bare-array list ordered by displayOrder.
  Future<dynamic> getBanners() => _client.get('/api/admin/banners');

  Future<Map<String, dynamic>> createBanner(Map<String, dynamic> body) async {
    final r = await _client.post('/api/admin/banners', body: body);
    return r is Map<String, dynamic> ? r : const {};
  }

  Future<Map<String, dynamic>> updateBanner(
    String id,
    Map<String, dynamic> body,
  ) async {
    final r = await _client.put('/api/admin/banners/$id', body: body);
    return r is Map<String, dynamic> ? r : const {};
  }

  Future<void> deleteBanner(String id) async {
    await _client.delete('/api/admin/banners/$id');
  }

  /// PATCH /reorder — server wants `{items: [{id, displayOrder}]}`.
  Future<void> reorderBanners(List<String> orderedIds) async {
    await _client.patch(
      '/api/admin/banners/reorder',
      body: {
        'items': [
          for (var i = 0; i < orderedIds.length; i++)
            {'id': orderedIds[i], 'displayOrder': i},
        ],
      },
    );
  }
}
