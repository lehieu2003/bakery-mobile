import 'package:bakery_mobile/src/core/auth/session_manager.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:bakery_mobile/src/features/auth/data/datasources/auth_api_service.dart';
import 'package:bakery_mobile/src/core/storage/token_storage.dart';

class AuthRepository {
  AuthRepository({required this.tokenStorage, required this.authApiService});

  final TokenStorage tokenStorage;
  final AuthApiService authApiService;

  Future<User> login({required String email, required String password}) async {
    final result = await authApiService.login(email: email, password: password);
    final user = result.user.toDomain();
    final token = result.token;
    if (token.isNotEmpty) {
      await _startSession(token);
    }
    return user;
  }

  Future<User> loginWithGoogle({String? idToken, String? accessToken}) async {
    final result = await authApiService.loginWithGoogle(
      idToken: idToken,
      accessToken: accessToken,
    );
    final user = result.user.toDomain();
    final token = result.token;
    if (token.isNotEmpty) {
      await _startSession(token);
    }
    return user;
  }

  /// Finishes an admin sign-in on a new phone with the emailed code.
  Future<User> verifyLogin({
    required String challengeId,
    required String otp,
  }) async {
    final result = await authApiService.verifyLogin(
      challengeId: challengeId,
      otp: otp,
    );
    if (result.token.isNotEmpty) await _startSession(result.token);
    return result.user.toDomain();
  }

  Future<void> register({required String email}) {
    return authApiService.register(email: email);
  }

  Future<User> registerVerify({
    required String email,
    required String otp,
    required String password,
    String? name,
  }) async {
    final result = await authApiService.registerVerify(
      email: email,
      otp: otp,
      password: password,
      name: name,
    );
    final user = result.user.toDomain();
    final token = result.token;
    if (token.isNotEmpty) {
      await _startSession(token);
    }
    return user;
  }

  /// Login responses carry no expiry: assume a full server lifetime so the
  /// session manager rotates it on schedule instead of immediately.
  Future<void> _startSession(String token) => tokenStorage.saveToken(
    token,
    expiresAt: DateTime.now().add(sessionLifetime),
  );

  Future<void> resetPassword({required String email}) {
    return authApiService.resetPassword(email: email);
  }

  Future<void> resetPasswordVerify({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return authApiService.resetPasswordVerify(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );
  }

  Future<User?> currentUser() async {
    final token = await tokenStorage.readToken();
    if (token == null || token.isEmpty) return null;

    try {
      return (await authApiService.me()).toDomain();
    } catch (_) {
      await tokenStorage.clearToken();
      return null;
    }
  }

  Future<User> updateProfile({String? name, String? phone}) async {
    return (await authApiService.updateProfile(
      name: name,
      phone: phone,
    )).toDomain();
  }

  Future<void> requestDeleteAccountOtp() =>
      authApiService.requestDeleteAccountOtp();

  /// The server revokes every session on success, so the local token goes
  /// too. On failure (wrong code, open orders) the session stays valid.
  Future<void> deleteAccount({required String otp}) async {
    await authApiService.deleteAccount(otp: otp);
    await tokenStorage.clearToken();
  }

  Future<void> logout() async {
    try {
      await authApiService.logout();
    } finally {
      await tokenStorage.clearToken();
    }
  }
}
