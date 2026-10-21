import 'package:bakery_mobile/src/core/storage/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _tokenKey = 'bakery_auth_token';
const _secure = FlutterSecureStorage();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void seed({
    Map<String, Object> prefs = const {},
    Map<String, String> secure = const {},
  }) {
    SharedPreferences.setMockInitialValues(prefs);
    // The mock writes into the map it is given — hand it a mutable copy.
    FlutterSecureStorage.setMockInitialValues(Map.of(secure));
  }

  test(
    'saveToken writes to secure storage, never to SharedPreferences',
    () async {
      seed();
      final storage = TokenStorage();

      await storage.saveToken('tok-1');

      expect(await storage.readToken(), 'tok-1');
      expect(await _secure.read(key: _tokenKey), 'tok-1');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_tokenKey), isNull);
    },
  );

  test('a token persisted by a previous run is read back', () async {
    seed(
      prefs: {'bakery_secure_token_ready': true},
      secure: {_tokenKey: 'tok-saved'},
    );

    expect(await TokenStorage().readToken(), 'tok-saved');
  });

  test('legacy plaintext token is migrated and removed from prefs', () async {
    seed(prefs: {_tokenKey: 'tok-legacy'});

    expect(await TokenStorage().readToken(), 'tok-legacy');
    expect(await _secure.read(key: _tokenKey), 'tok-legacy');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(_tokenKey), isNull);
  });

  test('stale keychain token from a previous install is discarded', () async {
    // iOS keeps keychain items across uninstall; SharedPreferences is wiped,
    // so a missing marker means "fresh install" → do not resurrect a session.
    seed(secure: {_tokenKey: 'tok-old-install'});

    expect(await TokenStorage().readToken(), isNull);
    expect(await _secure.read(key: _tokenKey), isNull);
  });

  test('clearToken removes the token everywhere', () async {
    seed();
    final storage = TokenStorage();
    await storage.saveToken('tok-1');

    await storage.clearToken();

    expect(await storage.readToken(), isNull);
    expect(await _secure.read(key: _tokenKey), isNull);
    expect(await TokenStorage().readToken(), isNull);
  });

  test('save during first read is not overwritten by the migration', () async {
    seed(prefs: {_tokenKey: 'tok-legacy'});
    final storage = TokenStorage();

    final pendingRead = storage.readToken();
    await storage.saveToken('tok-new');
    await pendingRead;

    expect(await storage.readToken(), 'tok-new');
    expect(await _secure.read(key: _tokenKey), 'tok-new');
  });

  test('expiresAt is stored with the token and cleared with it', () async {
    seed();
    final storage = TokenStorage();
    final expiresAt = DateTime.utc(2026, 11, 20, 8);

    await storage.saveToken('tok-1', expiresAt: expiresAt);
    expect(await storage.readExpiresAt(), expiresAt);
    // A new instance (app restart) reads it back from the secure store.
    expect(await TokenStorage().readExpiresAt(), expiresAt);

    await storage.saveToken('tok-2');
    expect(await storage.readExpiresAt(), isNull);

    await storage.saveToken('tok-3', expiresAt: expiresAt);
    await storage.clearToken();
    expect(await storage.readExpiresAt(), isNull);
    expect(await TokenStorage().readExpiresAt(), isNull);
  });

  test('a migrated legacy token has an unknown expiry', () async {
    seed(prefs: {_tokenKey: 'tok-legacy'});

    final storage = TokenStorage();
    expect(await storage.readToken(), 'tok-legacy');
    expect(await storage.readExpiresAt(), isNull);
  });
}
