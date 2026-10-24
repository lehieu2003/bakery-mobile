import 'package:bakery_mobile/src/core/network/api_client.dart';

/// Datasource over `/api/admin/notifications`.
class NotificationAdminApiService {
  const NotificationAdminApiService(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final r = await _client.get(
      '/api/admin/notifications',
      query: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return r is Map<String, dynamic> ? r : const {};
  }

  Future<Map<String, dynamic>> createNotification(
    Map<String, dynamic> body,
  ) async {
    final r = await _client.post('/api/admin/notifications', body: body);
    return r is Map<String, dynamic> ? r : const {};
  }
}
