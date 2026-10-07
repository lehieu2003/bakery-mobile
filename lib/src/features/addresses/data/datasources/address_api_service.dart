import 'package:bakery_mobile/src/core/network/api_client.dart';

/// Thin datasource over `/api/addresses`. Methods deal in raw JSON maps so
/// tests can substitute an in-memory fake without knowing about DTO parsing.
class AddressApiService {
  AddressApiService(this._client);

  final ApiClient _client;

  /// GET /api/addresses — the user's addresses, default first.
  Future<List<Map<String, dynamic>>> getAddresses() async {
    final response = await _client.get('/api/addresses');
    final data = response as Map<String, dynamic>;
    return (data['addresses'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  /// POST /api/addresses — creates an address for the current user.
  /// The server forces the first address to be the default one.
  Future<Map<String, dynamic>> createAddress({
    required String fullName,
    required String phone,
    required String street,
    required String ward,
    required String district,
    required String province,
    bool isDefault = false,
  }) async {
    final response = await _client.post(
      '/api/addresses',
      body: {
        'fullName': fullName,
        'phone': phone,
        'street': street,
        'ward': ward,
        'district': district,
        'province': province,
        if (isDefault) 'isDefault': true,
      },
    );
    final address = (response as Map<String, dynamic>)['address'];
    return address is Map<String, dynamic> ? address : const {};
  }

  /// PUT /api/addresses/[id] — partial update; `isDefault: true` auto-unsets
  /// the other defaults on the server.
  Future<Map<String, dynamic>> updateAddress(
    String id, {
    String? fullName,
    String? phone,
    String? street,
    String? ward,
    String? district,
    String? province,
    bool? isDefault,
  }) async {
    final response = await _client.put(
      '/api/addresses/${Uri.encodeComponent(id)}',
      body: {
        if (fullName != null) 'fullName': fullName,
        if (phone != null) 'phone': phone,
        if (street != null) 'street': street,
        if (ward != null) 'ward': ward,
        if (district != null) 'district': district,
        if (province != null) 'province': province,
        if (isDefault != null) 'isDefault': isDefault,
      },
    );
    final address = (response as Map<String, dynamic>)['address'];
    return address is Map<String, dynamic> ? address : const {};
  }

  /// DELETE /api/addresses/[id] — the server answers 404 for addresses that
  /// do not belong to the current user.
  Future<void> deleteAddress(String id) async {
    await _client.delete('/api/addresses/${Uri.encodeComponent(id)}');
  }
}
