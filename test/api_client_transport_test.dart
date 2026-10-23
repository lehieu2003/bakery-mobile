import 'dart:async';

import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient _client({Duration timeout = defaultRequestTimeout}) => ApiClient(
  baseUrl: 'http://api.test',
  tokenProvider: () async => null,
  requestTimeout: timeout,
);

void main() {
  test('a hung request fails with a readable ApiException', () async {
    final hung = Completer<http.Response>();
    await expectLater(
      http.runWithClient(
        () => _client(
          timeout: const Duration(milliseconds: 20),
        ).post('/api/orders', body: const {}),
        () => MockClient((_) => hung.future),
      ),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', isNull)
            .having((e) => e.message, 'message', contains('quá lâu')),
      ),
    );
  });

  test('a connection failure fails with a readable ApiException', () async {
    await expectLater(
      http.runWithClient(
        () => _client().get('/api/orders'),
        () => MockClient(
          (request) async =>
              throw http.ClientException('Connection refused', request.url),
        ),
      ),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', isNull)
            .having((e) => e.message, 'message', contains('kết nối')),
      ),
    );
  });

  test(
    'extra headers such as Idempotency-Key are sent with the request',
    () async {
      http.Request? seen;
      await http.runWithClient(
        () => _client().post(
          '/api/orders',
          body: const {},
          headers: const {'Idempotency-Key': 'abc123def456'},
        ),
        () => MockClient((request) async {
          seen = request;
          return http.Response('{"success":true,"data":{}}', 200);
        }),
      );
      expect(seen!.headers['Idempotency-Key'], 'abc123def456');
      expect(seen!.headers['Content-Type'], startsWith('application/json'));
    },
  );
}
