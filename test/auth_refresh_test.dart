import 'dart:convert';

import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/core/auth/session_manager.dart';
import 'package:bakery_mobile/src/core/storage/token_storage.dart';
import 'package:bakery_mobile/src/features/auth/data/datasources/auth_api_service.dart';
import 'package:bakery_mobile/src/features/auth/data/repositories/auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Future<T> _withServer<T>(
  Future<T> Function() body,
  http.Response Function(http.Request) handler,
) => http.runWithClient(body, () => MockClient((r) async => handler(r)));

AuthApiService _service(String token) => AuthApiService(
  ApiClient(baseUrl: 'http://api.test', tokenProvider: () async => token),
);

void main() {
  test(
    'refreshSession posts the current token and parses the rotation',
    () async {
      late http.Request sent;
      final session = await _withServer(
        () => _service('tok-old').refreshSession(),
        (request) {
          sent = request;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'token': 'tok-new',
                'expiresAt': '2026-11-20T09:00:00.000Z',
              },
            }),
            200,
          );
        },
      );

      expect(sent.method, 'POST');
      expect(sent.url.path, '/api/auth/refresh');
      expect(sent.headers['Authorization'], 'Bearer tok-old');
      expect(session.token, 'tok-new');
      expect(session.expiresAt, DateTime.utc(2026, 11, 20, 9));
    },
  );

  test('server refusal surfaces as ApiException 401', () async {
    await expectLater(
      _withServer(
        () => _service('tok-replayed').refreshSession(),
        (_) => http.Response(
          jsonEncode({
            'success': false,
            'error': 'Token reuse detected. All sessions have been revoked.',
          }),
          401,
        ),
      ),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
    );
  });

  test(
    'a malformed success body is an error, not a silent empty token',
    () async {
      await expectLater(
        _withServer(
          () => _service('tok-old').refreshSession(),
          (_) => http.Response(jsonEncode({'success': true, 'data': {}}), 200),
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'status', isNull),
        ),
      );
    },
  );

  test(
    'login stores the token with a full-lifetime expiry (no instant rotation)',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({
        'bakery_secure_token_ready': true,
      });
      FlutterSecureStorage.setMockInitialValues({});
      final storage = TokenStorage();
      final repo = AuthRepository(
        tokenStorage: storage,
        authApiService: AuthApiService(
          ApiClient(
            baseUrl: 'http://api.test',
            tokenProvider: () async => null,
          ),
        ),
      );

      final before = DateTime.now();
      await _withServer(
        () => repo.login(email: 'admin@bakery.vn', password: 'secret123'),
        (_) => http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'token': 'tok-login',
              'user': {
                'id': 'u-1',
                'email': 'admin@bakery.vn',
                'role': 'ADMIN',
              },
            },
          }),
          200,
        ),
      );

      expect(await storage.readToken(), 'tok-login');
      final expiresAt = (await storage.readExpiresAt())!;
      expect(
        expiresAt.difference(before),
        greaterThan(sessionLifetime - const Duration(minutes: 1)),
      );
      expect(
        expiresAt.difference(before),
        lessThan(sessionLifetime + const Duration(minutes: 1)),
      );
    },
  );
}
