import 'package:bakery_mobile/src/core/network/api_client.dart';

/// Tells bakery-web which device to push to for the signed-in user
/// (`/api/notifications/device-token`).
class DeviceTokenApiService {
  DeviceTokenApiService(this._client);

  final ApiClient _client;

  static const _path = '/api/notifications/device-token';

  Future<void> register({required String token, required String platform}) =>
      _client.post(_path, body: {'token': token, 'platform': platform});

  Future<void> revoke(String token) =>
      _client.delete(_path, body: {'token': token});
}
