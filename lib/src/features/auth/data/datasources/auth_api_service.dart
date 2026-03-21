import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:bakery_mobile/src/features/auth/data/dtos/user_dto.dart';

class AuthApiService {
  AuthApiService(this._client);

  final ApiClient _client;

  Future<AuthSessionDto> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/api/auth/login',
      body: {'email': email, 'password': password},
    );
    if (kDebugMode && response is Map<String, dynamic>) {
      debugPrint('[AUTH] login response keys: ${response.keys.toList()}');
      debugPrint(
        '[AUTH] token fields: token=${response['token'] != null}, accessToken=${response['accessToken'] != null}',
      );
    }

    return AuthSessionDto.fromJson(response as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _client.post('/api/auth/logout');
  }

  Future<UserDto> me() async {
    final response = await _client.get('/api/auth/me');
    final data = response as Map<String, dynamic>;
    return UserDto.fromJson(data['user'] as Map<String, dynamic>? ?? {});
  }

  Future<void> register({required String email}) async {
    await _client.post('/api/auth/register', body: {'email': email});
  }

  Future<AuthSessionDto> registerVerify({
    required String email,
    required String otp,
    required String password,
    String? name,
  }) async {
    final response = await _client.post(
      '/api/auth/register/verify',
      body: {
        'email': email,
        'otp': otp,
        'password': password,
        if (name != null && name.isNotEmpty) 'name': name,
      },
    );

    return AuthSessionDto.fromJson(response as Map<String, dynamic>);
  }

  Future<void> resetPassword({required String email}) async {
    await _client.post('/api/auth/reset-password', body: {'email': email});
  }

  Future<void> resetPasswordVerify({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _client.post(
      '/api/auth/reset-password/verify',
      body: {'email': email, 'otp': otp, 'newPassword': newPassword},
    );
  }
}
