import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_api_client.dart';
import '../../helpers/fixture.dart';

const _path = '/api/auth/delete-account';
const _success = 'auth/delete_account_success.json';
const _wrongOtp = 'auth/delete_account_wrong_otp.json';
const _openOrders = 'auth/delete_account_open_orders.json';

/// The real AuthViewModel + AuthRepository + TokenStorage on a FakeApiClient,
/// signed in through bootstrap (stored token + GET /api/auth/me).
Future<ProviderContainer> _signedIn(FakeApiClient api) async {
  final container = ProviderContainer(
    overrides: [apiClientProvider.overrideWithValue(api)],
  );
  addTearDown(container.dispose);
  api.stubFixture('GET', '/api/auth/me', 'auth/me_success.json');
  await container
      .read(tokenStorageProvider)
      .saveToken(
        'tok-1',
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
  await container.read(authViewModelProvider.notifier).bootstrap();
  expect(container.read(authViewModelProvider).isAuthenticated, isTrue);
  return container;
}

void main() {
  late FakeApiClient api;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    api = FakeApiClient();
  });

  test('success signs out and clears the stored token', () async {
    api.stubFixture('POST', _path, _success);
    final container = await _signedIn(api);
    final gate = api.hold('POST', _path);

    final deleting = container
        .read(authViewModelProvider.notifier)
        .deleteAccount(otp: '482913');
    expect(container.read(authViewModelProvider).isSubmitting, isTrue);
    gate.complete();
    final deleted = await deleting;

    final state = container.read(authViewModelProvider);
    expect(deleted, isTrue);
    expect(state.isAuthenticated, isFalse);
    expect(state.isSubmitting, isFalse);
    expect(state.errorMessage, isNull);
    expect(await container.read(tokenStorageProvider).readToken(), isNull);
    expect(api.callsTo('POST', _path).single.body, {'otp': '482913'});
  });

  test('wrong code keeps the session and reports the reason', () async {
    api.stubError('POST', _path, fixtureName: _wrongOtp, statusCode: 400);
    final container = await _signedIn(api);

    final deleted = await container
        .read(authViewModelProvider.notifier)
        .deleteAccount(otp: '000000');

    final state = container.read(authViewModelProvider);
    expect(deleted, isFalse);
    expect(state.isAuthenticated, isTrue);
    expect(state.errorMessage, fixtureError(_wrongOtp).message);
    expect(await container.read(tokenStorageProvider).readToken(), 'tok-1');
  });

  test('open orders block deletion with the server message', () async {
    api.stubError('POST', _path, fixtureName: _openOrders, statusCode: 409);
    final container = await _signedIn(api);

    final deleted = await container
        .read(authViewModelProvider.notifier)
        .deleteAccount(otp: '482913');

    final state = container.read(authViewModelProvider);
    expect(deleted, isFalse);
    expect(state.isAuthenticated, isTrue);
    expect(state.errorMessage, fixtureError(_openOrders).message);
  });

  test(
    'sending the code posts to the OTP route and keeps the session',
    () async {
      api.stubFixture(
        'POST',
        '/api/auth/delete-account/otp',
        'auth/delete_account_otp_success.json',
      );
      final container = await _signedIn(api);

      final sent = await container
          .read(authViewModelProvider.notifier)
          .sendDeleteAccountOtp();

      expect(sent, isTrue);
      expect(api.callsTo('POST', '/api/auth/delete-account/otp'), hasLength(1));
      expect(container.read(authViewModelProvider).isAuthenticated, isTrue);
    },
  );

  test('clearError drops a previous failure', () async {
    api.stubError('POST', _path, fixtureName: _wrongOtp, statusCode: 400);
    final container = await _signedIn(api);
    final vm = container.read(authViewModelProvider.notifier);
    await vm.deleteAccount(otp: '000000');

    vm.clearError();

    expect(container.read(authViewModelProvider).errorMessage, isNull);
  });
}
