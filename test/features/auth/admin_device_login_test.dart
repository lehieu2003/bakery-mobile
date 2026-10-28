import 'dart:convert';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/core/storage/device_id_storage.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/auth/presentation/screens/auth_screen.dart';
import 'package:bakery_mobile/src/features/auth/presentation/widgets/login_verification_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_api_client.dart';

const _loginPath = '/api/auth/login';
const _verifyPath = '/api/auth/login/verify';

const _adminJson = {
  'id': 'admin-1',
  'email': 'owner@bakery.vn',
  'name': 'Chủ tiệm',
  'role': 'ADMIN',
};

Map<String, Object?> _pendingCode() => {
  'requiresVerification': true,
  'challengeId': 'ch-1',
  'email': 'o***r@bakery.vn',
};

Map<String, Object?> _session() => {
  'token': 'session-token',
  'user': _adminJson,
};

ProviderContainer _container(FakeApiClient api) {
  final container = ProviderContainer(
    overrides: [apiClientProvider.overrideWithValue(api)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('this install keeps one device id', () async {
    final first = await DeviceIdStorage().read();
    expect(first.length, greaterThanOrEqualTo(16));
    expect(RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(first), isTrue);
    // A new instance (app restart) reads the same id back.
    expect(await DeviceIdStorage().read(), first);
  });

  test('every request carries the platform and device id', () async {
    late http.Request sent;
    final client = ApiClient(
      baseUrl: 'http://api.test',
      tokenProvider: () async => null,
      defaultHeaders: () async => {
        'x-client-platform': 'mobile',
        'x-device-id': 'device-1234567890ab',
      },
    );
    await http.runWithClient(
      () => client.get('/api/public/banners'),
      () => MockClient((request) async {
        sent = request;
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      }),
    );
    expect(sent.headers['x-client-platform'], 'mobile');
    expect(sent.headers['x-device-id'], 'device-1234567890ab');
  });

  test('an admin on a new phone waits for the code, then signs in', () async {
    final api = FakeApiClient()
      ..stub('POST', _loginPath, (_) => _pendingCode())
      ..stub('POST', _verifyPath, (_) => _session());
    final container = _container(api);
    final auth = container.read(authViewModelProvider.notifier);

    final signedIn = await auth.login(
      email: 'owner@bakery.vn',
      password: 'secret',
    );

    expect(signedIn, isFalse);
    var state = container.read(authViewModelProvider);
    expect(state.user, isNull);
    expect(state.errorMessage, isNull, reason: 'the code step is no error');
    expect(state.pendingVerification?.challengeId, 'ch-1');
    expect(state.pendingVerification?.maskedEmail, 'o***r@bakery.vn');

    expect(await auth.verifyLogin('123456'), isTrue);
    state = container.read(authViewModelProvider);
    expect(state.user?.role, 'ADMIN');
    expect(state.pendingVerification, isNull);
    expect(api.callsTo('POST', _verifyPath).single.body, {
      'challengeId': 'ch-1',
      'otp': '123456',
    });
    expect(
      await container.read(tokenStorageProvider).readToken(),
      'session-token',
    );
  });

  test('a wrong code keeps the code step with the server message', () async {
    final api = FakeApiClient()
      ..stub('POST', _loginPath, (_) => _pendingCode())
      ..stub(
        'POST',
        _verifyPath,
        (_) => throw ApiException(
          'Mã xác minh không đúng hoặc đã hết hạn',
          statusCode: 400,
        ),
      );
    final container = _container(api);
    final auth = container.read(authViewModelProvider.notifier);
    await auth.login(email: 'owner@bakery.vn', password: 'secret');

    expect(await auth.verifyLogin('000000'), isFalse);
    final state = container.read(authViewModelProvider);
    expect(state.user, isNull);
    expect(state.pendingVerification, isNotNull);
    expect(state.errorMessage, 'Mã xác minh không đúng hoặc đã hết hạn');

    auth.cancelVerification();
    expect(container.read(authViewModelProvider).pendingVerification, isNull);
  });

  testWidgets('the sign-in screen switches to the code step', (tester) async {
    final api = FakeApiClient()
      ..stub('POST', _loginPath, (_) => _pendingCode())
      ..stub('POST', _verifyPath, (_) => _session());
    final container = _container(api);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.light(), home: const AuthScreen()),
      ),
    );

    await container
        .read(authViewModelProvider.notifier)
        .login(email: 'owner@bakery.vn', password: 'secret');
    await tester.pumpAndSettle();

    expect(find.byType(LoginVerificationView), findsOneWidget);
    expect(find.textContaining('o***r@bakery.vn'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mã xác minh'),
      '12 34 56',
    );
    await tester.tap(find.text('Xác minh'));
    await tester.pumpAndSettle();

    expect(api.callsTo('POST', _verifyPath).single.body, {
      'challengeId': 'ch-1',
      'otp': '123456',
    });
    expect(container.read(authViewModelProvider).user?.role, 'ADMIN');
  });
}
