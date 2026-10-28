import 'package:bakery_mobile/src/core/auth/session_manager.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:bakery_mobile/src/features/auth/data/dtos/user_dto.dart';

/// An admin signed in from a phone that is not their trusted one: no
/// session yet; bakery-web emailed a code to [maskedEmail]. Finish with
/// [AuthApiService.verifyLogin].
class LoginVerificationRequired implements Exception {
  const LoginVerificationRequired({
    required this.challengeId,
    required this.maskedEmail,
  });

  final String challengeId;
  final String maskedEmail;

  /// The pending-code reply of a sign-in endpoint, or null for a session.
  static LoginVerificationRequired? fromResponse(Object? response) {
    if (response is! Map<String, dynamic>) return null;
    if (response['requiresVerification'] != true) return null;
    final challengeId = '${response['challengeId'] ?? ''}';
    if (challengeId.isEmpty) return null;
    return LoginVerificationRequired(
      challengeId: challengeId,
      maskedEmail: '${response['email'] ?? ''}',
    );
  }
}

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

    final pending = LoginVerificationRequired.fromResponse(response);
    if (pending != null) throw pending;
    return AuthSessionDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST /api/auth/login/verify — the emailed code for an admin sign-in on
  /// a new phone; this phone becomes the trusted one.
  Future<AuthSessionDto> verifyLogin({
    required String challengeId,
    required String otp,
  }) async {
    final response = await _client.post(
      '/api/auth/login/verify',
      body: {'challengeId': challengeId, 'otp': otp},
    );
    return AuthSessionDto.fromJson(response as Map<String, dynamic>);
  }

  Future<AuthSessionDto> loginWithGoogle({
    String? idToken,
    String? accessToken,
  }) async {
    final response = await _client.post(
      '/api/auth/google/mobile',
      body: {
        if (idToken != null) 'idToken': idToken,
        if (accessToken != null) 'accessToken': accessToken,
      },
    );
    final pending = LoginVerificationRequired.fromResponse(response);
    if (pending != null) throw pending;
    return AuthSessionDto.fromJson(response as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _client.post('/api/auth/logout');
  }

  /// POST /api/auth/refresh — rotates the session this client authenticates
  /// with (single use: the presented token is revoked). Returns
  /// `{ token, expiresAt }`; a 401 means the session is gone.
  Future<RefreshedSession> refreshSession() async {
    final response = await _client.post('/api/auth/refresh');
    final data = response is Map<String, dynamic> ? response : const {};
    final token = data['token'];
    final expiresAt = DateTime.tryParse('${data['expiresAt'] ?? ''}');
    if (token is! String || token.isEmpty || expiresAt == null) {
      throw ApiException('Invalid refresh response');
    }
    return RefreshedSession(token: token, expiresAt: expiresAt);
  }

  Future<UserDto> me() async {
    final response = await _client.get('/api/auth/me');
    final data = response as Map<String, dynamic>;
    return UserDto.fromJson(data['user'] as Map<String, dynamic>? ?? {});
  }

  Future<UserDto> updateProfile({String? name, String? phone}) async {
    final response = await _client.patch(
      '/api/auth/me',
      body: {'name': name?.trim() ?? '', 'phone': phone?.trim() ?? ''},
    );
    final data = response as Map<String, dynamic>;
    return UserDto.fromJson(data['user'] as Map<String, dynamic>? ?? {});
  }

  /// Anonymizes the signed-in customer server-side (Play account-deletion
  /// requirement), confirmed with the emailed code. 400 wrong/expired code,
  /// 403 admin, 409 open orders.
  Future<void> deleteAccount({required String otp}) async {
    await _client.post('/api/auth/delete-account', body: {'otp': otp});
  }

  /// Emails the code that confirms deletion to the signed-in account. Works
  /// for Google sign-in accounts too, which have no password. 429 = cooldown.
  Future<void> requestDeleteAccountOtp() async {
    await _client.post('/api/auth/delete-account/otp', body: const {});
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
      '/api/auth/verify-email',
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
