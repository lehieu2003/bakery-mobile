import 'dart:async';

import 'package:bakery_mobile/src/core/auth/session_manager.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/core/storage/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime.utc(2026, 10, 21, 9);

/// Scripted refresher: records the tokens it was asked to rotate and replays
/// [next] (a result, an error to throw, or a Completer to await).
class _Refresher {
  final List<String> calls = [];
  Object? next;

  Future<RefreshedSession> call(String token) async {
    calls.add(token);
    final value = next;
    if (value is Completer<RefreshedSession>) return value.future;
    if (value is RefreshedSession) return value;
    throw value ?? StateError('no scripted result');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TokenStorage storage;
  late _Refresher refresher;
  late DateTime clock;
  late SessionManager manager;

  setUp(() {
    SharedPreferences.setMockInitialValues({'bakery_secure_token_ready': true});
    FlutterSecureStorage.setMockInitialValues({});
    storage = TokenStorage();
    refresher = _Refresher();
    clock = _now;
    manager = SessionManager(
      storage: storage,
      refresh: refresher.call,
      now: () => clock,
    );
  });

  test('no token → null, never refreshes', () async {
    expect(await manager.validToken(), isNull);
    expect(refresher.calls, isEmpty);
  });

  test('a recently issued token is used as is', () async {
    await storage.saveToken(
      'tok-1',
      expiresAt: _now.add(const Duration(days: 29)),
    );

    expect(await manager.validToken(), 'tok-1');
    expect(refresher.calls, isEmpty);
  });

  test('a token past the rotation age is rotated and persisted', () async {
    await storage.saveToken(
      'tok-old',
      expiresAt: _now.add(const Duration(days: 20)),
    );
    refresher.next = RefreshedSession(
      token: 'tok-new',
      expiresAt: _now.add(const Duration(days: 30)),
    );

    expect(await manager.validToken(), 'tok-new');
    expect(refresher.calls, ['tok-old']);
    expect(await storage.readToken(), 'tok-new');
    expect(await storage.readExpiresAt(), _now.add(sessionLifetime));
  });

  test('unknown expiry (legacy token) is rotated right away', () async {
    await storage.saveToken('tok-legacy');
    refresher.next = RefreshedSession(
      token: 'tok-new',
      expiresAt: _now.add(sessionLifetime),
    );

    expect(await manager.validToken(), 'tok-new');
    expect(refresher.calls, ['tok-legacy']);
  });

  test('concurrent callers share one refresh (never replay a token)', () async {
    await storage.saveToken('tok-old');
    final pending = Completer<RefreshedSession>();
    refresher.next = pending;

    final results = Future.wait([
      manager.validToken(),
      manager.validToken(),
      manager.validToken(),
    ]);
    await Future<void>.delayed(Duration.zero);
    pending.complete(
      RefreshedSession(token: 'tok-new', expiresAt: _now.add(sessionLifetime)),
    );

    expect(await results, ['tok-new', 'tok-new', 'tok-new']);
    expect(refresher.calls, ['tok-old']);
  });

  test('401 from refresh (expired/revoked) clears the session', () async {
    await storage.saveToken('tok-old');
    refresher.next = ApiException('Unauthorized', statusCode: 401);

    expect(await manager.validToken(), isNull);
    expect(await storage.readToken(), isNull);
  });

  test('network failure keeps the still-valid token and backs off', () async {
    await storage.saveToken(
      'tok-old',
      expiresAt: _now.add(const Duration(days: 20)),
    );
    refresher.next = ApiException('Không có kết nối');

    expect(await manager.validToken(), 'tok-old');
    expect(await storage.readToken(), 'tok-old');

    // Within the back-off window: no new attempt.
    clock = _now.add(const Duration(minutes: 2));
    expect(await manager.validToken(), 'tok-old');
    expect(refresher.calls, hasLength(1));

    // After it: retried, and this time it succeeds.
    clock = _now.add(refreshRetryDelay + const Duration(seconds: 1));
    refresher.next = RefreshedSession(
      token: 'tok-new',
      expiresAt: clock.add(sessionLifetime),
    );
    expect(await manager.validToken(), 'tok-new');
    expect(refresher.calls, hasLength(2));
  });

  test(
    'past its local expiry the server still decides (clock may be wrong)',
    () async {
      await storage.saveToken(
        'tok-old',
        expiresAt: _now.subtract(const Duration(minutes: 1)),
      );
      refresher.next = ApiException('Unauthorized', statusCode: 401);

      expect(await manager.validToken(), isNull);
      expect(refresher.calls, ['tok-old']);
      expect(await storage.readToken(), isNull);
    },
  );

  test(
    'rotation schedule follows the device clock, not server expiresAt',
    () async {
      // Device clock 8 days ahead of the server: the server's expiresAt is only
      // 22 device-days away. Scheduling on it would rotate on every request.
      await storage.saveToken('tok-old');
      refresher.next = RefreshedSession(
        token: 'tok-new',
        expiresAt: _now.add(const Duration(days: 22)),
      );

      expect(await manager.validToken(), 'tok-new');
      expect(await storage.readExpiresAt(), _now.add(sessionLifetime));

      clock = _now.add(const Duration(hours: 1));
      expect(await manager.validToken(), 'tok-new');
      expect(refresher.calls, ['tok-old']);
    },
  );

  test('a login after the token was cleared is not overwritten', () async {
    await storage.saveToken('tok-old');
    final pending = Completer<RefreshedSession>();
    refresher.next = pending;

    final refreshing = manager.validToken();
    await Future<void>.delayed(Duration.zero);
    // User logs out and back in while the old token is being rotated.
    await storage.saveToken('tok-login', expiresAt: _now.add(sessionLifetime));
    pending.complete(
      RefreshedSession(
        token: 'tok-rotated',
        expiresAt: _now.add(sessionLifetime),
      ),
    );

    expect(await refreshing, 'tok-login');
    expect(await storage.readToken(), 'tok-login');
  });
}
