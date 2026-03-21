import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';

class AuthApiService {
  AuthApiService(this._client);

  final ApiClient _client;

  Future<(User, String)> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/api/auth/login',
      body: {'email': email, 'password': password},
    );

    final data = response as Map<String, dynamic>;
    final user = User.fromJson(data['user'] as Map<String, dynamic>? ?? {});
    final token = data['token']?.toString() ?? '';
    return (user, token);
  }

  Future<void> logout() async {
    await _client.post('/api/auth/logout');
  }

  Future<User> me() async {
    final response = await _client.get('/api/auth/me');
    final data = response as Map<String, dynamic>;
    return User.fromJson(data['user'] as Map<String, dynamic>? ?? {});
  }

  Future<void> register({required String email}) async {
    await _client.post('/api/auth/register', body: {'email': email});
  }

  Future<(User, String)> registerVerify({
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

    final data = response as Map<String, dynamic>;
    final user = User.fromJson(data['user'] as Map<String, dynamic>? ?? {});
    final token = data['token']?.toString() ?? '';
    return (user, token);
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


