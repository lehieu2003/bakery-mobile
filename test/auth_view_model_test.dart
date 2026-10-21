import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/core/storage/token_storage.dart';
import 'package:bakery_mobile/src/features/auth/data/datasources/auth_api_service.dart';
import 'package:bakery_mobile/src/features/auth/data/repositories/auth_repository.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fake pattern như test/reviews_controller_test.dart: subclass + override,
/// SharedPreferences + FlutterSecureStorage mock trong setUp() (TokenStorage
/// dùng cả hai). The overrides never touch the network — `login` and
/// `registerVerify` return the canned user directly.
class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository(this._user)
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
  Future<User> login({required String email, required String password}) async =>
      _user;

  @override
  Future<User> registerVerify({
    required String email,
    required String otp,
    required String password,
    String? name,
  }) async => _user;
}

User _user(String role) => User(id: 'u-1', email: 'test@bakery.vn', role: role);

/// Repository whose `logout()` always fails (expired/offline session) — the
/// real one clears the token then rethrows, which this fake mirrors by
/// throwing directly.
class _FailingLogoutAuthRepository extends AuthRepository {
  _FailingLogoutAuthRepository(this._user)
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
  Future<User> login({required String email, required String password}) async =>
      _user;

  @override
  Future<void> logout() async =>
      throw ApiException('session expired', statusCode: 401);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('login accepts an ADMIN account and stores it in state', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _FakeAuthRepository(_user('ADMIN')),
        ),
      ],
    );
    addTearDown(container.dispose);

    final submitted = await container
        .read(authViewModelProvider.notifier)
        .login(email: 'admin@bakery.vn', password: 'secret');

    expect(submitted, isTrue);
    expect(container.read(authViewModelProvider).user!.role, 'ADMIN');
    expect(container.read(authViewModelProvider).errorMessage, isNull);
  });

  test(
    'verifyRegister accepts an ADMIN account and stores it in state',
    () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _FakeAuthRepository(_user('ADMIN')),
          ),
        ],
      );
      addTearDown(container.dispose);

      final submitted = await container
          .read(authViewModelProvider.notifier)
          .verifyRegister(
            email: 'admin@bakery.vn',
            otp: '123456',
            password: 'secret',
          );

      expect(submitted, isTrue);
      expect(container.read(authViewModelProvider).user!.role, 'ADMIN');
      expect(container.read(authViewModelProvider).errorMessage, isNull);
    },
  );

  test('login still accepts a CUSTOMER account (regression guard)', () async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _FakeAuthRepository(_user('CUSTOMER')),
        ),
      ],
    );
    addTearDown(container.dispose);

    final submitted = await container
        .read(authViewModelProvider.notifier)
        .login(email: 'test@bakery.vn', password: 'secret');

    expect(submitted, isTrue);
    expect(container.read(authViewModelProvider).user!.role, 'CUSTOMER');
  });

  test(
    'logout ends the session client-side even when the API call fails',
    () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _FailingLogoutAuthRepository(_user('ADMIN')),
          ),
        ],
      );
      addTearDown(container.dispose);

      final viewModel = container.read(authViewModelProvider.notifier);
      await viewModel.login(email: 'admin@bakery.vn', password: 'secret');
      expect(container.read(authViewModelProvider).isAuthenticated, isTrue);

      await viewModel.logout();

      final state = container.read(authViewModelProvider);
      expect(state.user, isNull);
      expect(state.isAuthenticated, isFalse);
      expect(state.isSubmitting, isFalse);
    },
  );
}
