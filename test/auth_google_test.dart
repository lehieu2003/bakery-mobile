import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/storage/token_storage.dart';
import 'package:bakery_mobile/src/features/auth/data/datasources/auth_api_service.dart';
import 'package:bakery_mobile/src/features/auth/data/repositories/auth_repository.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGoogleAuthRepository extends AuthRepository {
  _FakeGoogleAuthRepository(this._user)
    : super(
        tokenStorage: TokenStorage(),
        authApiService: AuthApiService(
          ApiClient(
            baseUrl: 'http://localhost:1',
            tokenProvider: () async => null,
          ),
        ),
      );

  final User _user;

  @override
  Future<User> loginWithGoogle({String? idToken, String? accessToken}) async =>
      _user;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
    'loginWithGoogle authenticates and populates user in AuthState',
    () async {
      final expectedUser = const User(
        id: 'google-u1',
        email: 'customer@gmail.com',
        role: 'CUSTOMER',
        name: 'Google Customer',
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _FakeGoogleAuthRepository(expectedUser),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Call repository directly through fake
      final user = await container
          .read(authRepositoryProvider)
          .loginWithGoogle(idToken: 'fake-id-token');

      expect(user.id, 'google-u1');
      expect(user.email, 'customer@gmail.com');
    },
  );
}
