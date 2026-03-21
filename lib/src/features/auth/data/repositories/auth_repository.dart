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
      await tokenStorage.saveToken(token);
    }
    return user;
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
      await tokenStorage.saveToken(token);
    }
    return user;
  }

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

  Future<void> logout() async {
    try {
      await authApiService.logout();
    } finally {
      await tokenStorage.clearToken();
    }
  }
}
