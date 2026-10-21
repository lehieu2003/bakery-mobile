import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the session token in the platform secure store (Android
/// Keystore-backed cipher, iOS/macOS Keychain) instead of plaintext
/// SharedPreferences.
///
/// The token is cached in memory: [readToken] runs before every API request,
/// and secure-store reads are far slower than a field access.
///
/// First read per install ([_initialize]):
/// - a token left in SharedPreferences by older app versions is moved into
///   the secure store, so upgrading users stay signed in;
/// - otherwise any secure-store token is dropped — iOS keeps Keychain items
///   across uninstall while SharedPreferences is wiped, so a missing marker
///   means a fresh install that must not resurrect the previous session.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? secureStorage})
    : _secure = secureStorage ?? const FlutterSecureStorage();

  static const _tokenKey = 'bakery_auth_token';
  static const _installMarkerKey = 'bakery_secure_token_ready';

  final FlutterSecureStorage _secure;
  String? _cached;
  Future<void>? _init;

  Future<String?> readToken() async {
    await _ensureInitialized();
    return _cached;
  }

  Future<void> saveToken(String token) async {
    await _ensureInitialized();
    _cached = token;
    try {
      await _secure.write(key: _tokenKey, value: token);
    } catch (error) {
      // Keep the in-memory session usable; it just won't survive a restart.
      debugPrint('TokenStorage: secure write failed: $error');
    }
  }

  Future<void> clearToken() async {
    await _ensureInitialized();
    _cached = null;
    try {
      await _secure.delete(key: _tokenKey);
    } catch (error) {
      debugPrint('TokenStorage: secure delete failed: $error');
    }
  }

  Future<void> _ensureInitialized() => _init ??= _initialize();

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_installMarkerKey) != true) {
        final legacy = prefs.getString(_tokenKey);
        if (legacy != null && legacy.isNotEmpty) {
          await _secure.write(key: _tokenKey, value: legacy);
        } else {
          await _secure.delete(key: _tokenKey);
        }
        await prefs.remove(_tokenKey);
        await prefs.setBool(_installMarkerKey, true);
      }
      _cached = await _secure.read(key: _tokenKey);
    } catch (error) {
      // An unreadable store (e.g. Keystore reset) means "signed out", not a
      // crash at startup.
      debugPrint('TokenStorage: secure read failed: $error');
      _cached = null;
    }
  }
}
