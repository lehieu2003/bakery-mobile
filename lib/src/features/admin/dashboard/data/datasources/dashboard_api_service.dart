import 'package:bakery_mobile/src/core/network/api_client.dart';

/// Thin datasource over `/api/admin/dashboard`. Methods deal in raw JSON
/// maps so tests can substitute a fake [ApiClient] without knowing about
/// DTO parsing.
class DashboardApiService {
  const DashboardApiService(this._client);

  final ApiClient _client;

  /// GET /api/admin/dashboard — aggregated KPI/chart/recent-order stats for
  /// the trailing [windowDays] days. Requires the ADMIN role.
  Future<Map<String, dynamic>> getDashboard({int windowDays = 7}) async {
    final response = await _client.get(
      '/api/admin/dashboard',
      query: {'windowDays': windowDays},
    );
    return response as Map<String, dynamic>? ?? const {};
  }
}
