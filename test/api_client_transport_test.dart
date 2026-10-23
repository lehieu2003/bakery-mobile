import 'dart:convert';
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

  Future<ApiException> failure(MockClient server) async {
    try {
      await http.runWithClient(
        () => _client().get('/api/orders'),
        () => server,
      );
    } on ApiException catch (error) {
      return error;
    }
    fail('expected an ApiException');
  }

  test('a proxy HTML 502 page never becomes the message', () async {
    final error = await failure(
      MockClient(
        (_) async =>
            http.Response('<html><body>502 Bad Gateway</body></html>', 502),
      ),
    );
    expect(error.kind, ApiErrorKind.server);
    expect(error.statusCode, 502);
    expect(error.message, serverErrorMessage);
  });

  test('a 500 hides the server English internals', () async {
    final error = await failure(
      MockClient(
        (_) async => http.Response(
          '{"success":false,"error":"Failed to fetch orders"}',
          500,
        ),
      ),
    );
    expect(error.kind, ApiErrorKind.server);
    expect(error.message, serverErrorMessage);
  });

  test('a 4xx keeps the server message, written for users', () async {
    final error = await failure(
      MockClient(
        (_) async => http.Response.bytes(
          utf8.encode('{"success":false,"error":"Mã giảm giá đã hết hạn"}'),
          400,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    expect(error.kind, ApiErrorKind.client);
    expect(error.message, 'Mã giảm giá đã hết hạn');
  });

  test('a TLS-style transport failure is a network error', () async {
    final error = await failure(
      MockClient((_) async => throw const FormatException('handshake failed')),
    );
    expect(error.kind, ApiErrorKind.network);
    expect(error.isConnectivityIssue, isTrue);
    expect(error.message, networkErrorMessage);
  });

  test('a programming error is not disguised as a network error', () async {
    await expectLater(
      http.runWithClient(
        () => _client().get('/api/orders'),
        () => MockClient((_) async => throw StateError('bug')),
      ),
      throwsA(isA<StateError>()),
    );
  });
}
