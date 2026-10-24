import 'package:bakery_mobile/src/core/network/api_client.dart';

/// Thin datasource over `/api/admin/customers`. Methods deal in raw JSON
/// maps so tests can substitute a fake [ApiClient] without knowing about
/// DTO parsing.
class CustomerAdminApiService {
  const CustomerAdminApiService(this._client);

  final ApiClient _client;

  /// GET /api/admin/customers — paginated admin customer list (newest
  /// first). [search] matches name / email / phone server-side; [level]
  /// filters by an uppercase member level (SILVER | GOLD | PLATINUM).
  /// Requires the ADMIN role. Returns
  /// `{ customers: [...], pagination: {...} }`.
  Future<Map<String, dynamic>> getCustomers({
    int page = 1,
    int limit = 50,
    String? search,
    String? level,
  }) async {
    final response = await _client.get(
      '/api/admin/customers',
      query: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (level != null && level.isNotEmpty) 'level': level,
      },
    );
    return response as Map<String, dynamic>? ?? const {};
  }

  /// GET /api/admin/customers/{id} — customer detail by id, including the
  /// recent orders, payments and notifications blocks. Returns the customer
  /// object directly.
  Future<Map<String, dynamic>> getCustomer(String id) async {
    final response = await _client.get('/api/admin/customers/$id');
    return response as Map<String, dynamic>? ?? const {};
  }

  /// PATCH /api/admin/customers/{id} — update member level and/or points.
  /// Only non-null keys are sent; the server re-validates the level.
  /// Returns the updated customer object directly.
  Future<Map<String, dynamic>> updateCustomer(
    String id, {
    String? memberLevel,
    int? points,
  }) async {
    final response = await _client.patch(
      '/api/admin/customers/$id',
      body: {
        if (memberLevel != null) 'memberLevel': memberLevel,
        if (points != null) 'points': points,
      },
    );
    return response as Map<String, dynamic>? ?? const {};
  }
}
