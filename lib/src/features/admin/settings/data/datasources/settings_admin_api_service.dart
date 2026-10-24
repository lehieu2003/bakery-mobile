import 'package:bakery_mobile/src/core/network/api_client.dart';

/// Datasource over `/api/admin/settings`.
class SettingsAdminApiService {
  const SettingsAdminApiService(this._client);

  final ApiClient _client;

  Future<dynamic> getSettings() => _client.get('/api/admin/settings');

  Future<void> putSettings(Map<String, dynamic> body) async {
    await _client.put('/api/admin/settings', body: body);
  }
}
