import 'package:bakery_mobile/src/core/network/api_client.dart';

/// Datasource over `/api/admin/membership`.
class MembershipAdminApiService {
  const MembershipAdminApiService(this._client);

  final ApiClient _client;

  Future<dynamic> getMembership() => _client.get('/api/admin/membership');

  Future<void> putMembership(Map<String, dynamic> body) async {
    await _client.put('/api/admin/membership', body: body);
  }
}
