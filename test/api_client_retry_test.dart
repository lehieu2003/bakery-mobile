import 'dart:convert';

import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Server stub: accepts only [validToken]; records every Authorization header.
MockClient _server(String validToken, List<String?> seen) =>
    MockClient((request) async {
      final auth = request.headers['Authorization'];
      seen.add(auth);
      if (auth == 'Bearer $validToken') {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'ok': true},
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({'success': false, 'error': 'Unauthorized'}),
        401,
      );
    });

void main() {
  test(
    '401 with a token rotated meanwhile is retried once with the new one',
    () async {
      final seen = <String?>[];
      final tokens = ['tok-old', 'tok-new'];
      final client = ApiClient(
        baseUrl: 'http://api.test',
        tokenProvider: () async =>
            tokens.length > 1 ? tokens.removeAt(0) : tokens.first,
      );

      final data = await http.runWithClient(
        () => client.get('/api/admin/orders'),
        () => _server('tok-new', seen),
      );

      expect(data, {'ok': true});
      expect(seen, ['Bearer tok-old', 'Bearer tok-new']);
    },
  );

  test('401 with an unchanged token is not retried', () async {
    final seen = <String?>[];
    final client = ApiClient(
      baseUrl: 'http://api.test',
      tokenProvider: () async => 'tok-old',
    );

    await expectLater(
      http.runWithClient(
        () => client.get('/api/admin/orders'),
        () => _server('tok-new', seen),
      ),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
    );
    expect(seen, ['Bearer tok-old']);
  });

  test('anonymous 401 is not retried even if a token appears', () async {
    final seen = <String?>[];
    final tokens = <String?>[null, 'tok-new'];
    final client = ApiClient(
      baseUrl: 'http://api.test',
      tokenProvider: () async => tokens.removeAt(0),
    );

    await expectLater(
      http.runWithClient(
        () => client.post('/api/auth/login'),
        () => _server('tok-new', seen),
      ),
      throwsA(isA<ApiException>()),
    );
    expect(seen, [null]);
  });

  test('a second 401 after the retry is surfaced (no loop)', () async {
    final seen = <String?>[];
    var n = 0;
    final client = ApiClient(
      baseUrl: 'http://api.test',
      tokenProvider: () async => 'tok-${n++}',
    );

    await expectLater(
      http.runWithClient(
        () => client.get('/api/admin/orders'),
        () => _server('never', seen),
      ),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
    );
    expect(seen, ['Bearer tok-0', 'Bearer tok-1']);
  });
}
