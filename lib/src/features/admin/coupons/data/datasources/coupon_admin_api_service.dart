import 'package:bakery_mobile/src/core/network/api_client.dart';

/// Datasource over `/api/admin/coupons`.
class CouponAdminApiService {
  const CouponAdminApiService(this._client);

  final ApiClient _client;

  Future<dynamic> getCoupons() => _client.get('/api/admin/coupons');

  Future<Map<String, dynamic>> createCoupon(Map<String, dynamic> body) async {
    final r = await _client.post('/api/admin/coupons', body: body);
    return r is Map<String, dynamic> ? r : const {};
  }

  Future<void> deleteCoupon(String id) async {
    await _client.delete('/api/admin/coupons/$id');
  }

  Future<void> updateCoupon(String id, Map<String, dynamic> body) async {
    await _client.put('/api/admin/coupons/$id', body: body);
  }
}
