import 'package:bakery_mobile/src/core/network/api_client.dart';

/// Datasource over `/api/admin/audit`.
class AuditAdminApiService {
  const AuditAdminApiService(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> getAudit({int page = 1, int limit = 20}) async {
    final r = await _client.get(
      '/api/admin/audit',
      query: {'page': page, 'limit': limit},
    );
    return r is Map<String, dynamic> ? r : const {};
  }
}
