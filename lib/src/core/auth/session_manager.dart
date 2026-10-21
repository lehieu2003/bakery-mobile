import 'package:flutter/foundation.dart';

import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/core/storage/token_storage.dart';

/// Server session lifetime — mirrors `SESSION_EXPIRY_DAYS` in bakery-web
/// (`lib/session.ts`, `lib/auth/session-rotation.ts`). Login responses carry
/// no expiry, so a fresh login is assumed to live this long.
const Duration sessionLifetime = Duration(days: 30);

/// Rotate once fewer than this many days remain, i.e. about weekly. Anyone
/// opening the app at least once per [sessionLifetime] stays signed in.
const Duration rotateWhenRemainingBelow = Duration(days: 23);

/// After a refresh fails for a non-auth reason (offline, 5xx) the current,
/// still-valid token keeps being used; the next attempt waits this long.
const Duration refreshRetryDelay = Duration(minutes: 5);

/// A rotated session as returned by `POST /api/auth/refresh`. [expiresAt]
/// is in server time and deliberately not used for scheduling (see
/// [SessionManager]).
class RefreshedSession {
  const RefreshedSession({required this.token, required this.expiresAt});

  final String token;
  final DateTime expiresAt;
}

/// Exchanges [token] for a new session. Must throw [ApiException] with
/// status 401 when the server refuses the token.
typedef SessionRefresher = Future<RefreshedSession> Function(String token);

/// Keeps the bearer session alive by rotating it before it expires.
///
/// bakery-web's refresh is single-use rotation: the old token is revoked
/// the moment a new one is issued, and presenting an already-rotated token
/// is treated as theft — the server then revokes *every* session of the
/// user. Hence:
/// - at most one refresh runs at a time; concurrent callers share it;
/// - a token is never sent to refresh twice (a failed attempt is retried
///   only after [refreshRetryDelay], and only for non-auth failures);
/// - a refresh result is dropped if the stored session changed meanwhile
///   (logout / new login).
///
/// Scheduling uses only the device clock: the stored expiry is "device time
/// of issue + [sessionLifetime]", never the server's `expiresAt`. Mixing the
/// two made a device clock running ahead re-rotate on every request. And the
/// device never declares a session dead by itself — past its local expiry it
/// still asks the server, whose 401 is the only signal that clears it.
class SessionManager {
  SessionManager({
    required TokenStorage storage,
    required SessionRefresher refresh,
    DateTime Function()? now,
  }) : _storage = storage,
       _refresh = refresh,
       _now = now ?? DateTime.now;

  final TokenStorage _storage;
  final SessionRefresher _refresh;
  final DateTime Function() _now;

  Future<String?>? _inFlight;
  DateTime? _retryAfter;

  /// The token to authenticate the next request with, rotated first when it
  /// is due. Null when signed out (or the session could not be kept).
  Future<String?> validToken() async {
    final pending = _inFlight;
    if (pending != null) return pending;

    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return null;
    final expiresAt = await _storage.readExpiresAt();
    final now = _now();

    final due =
        expiresAt == null ||
        expiresAt.difference(now) < rotateWhenRemainingBelow;
    final retryAfter = _retryAfter;
    if (!due || (retryAfter != null && now.isBefore(retryAfter))) {
      return token;
    }
    // Re-checked after the awaits above: another caller may have started.
    return _inFlight ??= _rotate(token).whenComplete(() => _inFlight = null);
  }

  Future<String?> _rotate(String token) async {
    try {
      final rotated = await _refresh(token);
      if (await _storage.readToken() != token) return _storage.readToken();
      await _storage.saveToken(
        rotated.token,
        expiresAt: _now().add(sessionLifetime),
      );
      _retryAfter = null;
      return rotated.token;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        // Expired, revoked, or replay-detected: the session is gone.
        if (await _storage.readToken() == token) await _storage.clearToken();
        return _storage.readToken();
      }
      return _deferRetry(token, error);
    } catch (error) {
      return _deferRetry(token, error);
    }
  }

  String _deferRetry(String token, Object error) {
    debugPrint('SessionManager: refresh deferred: $error');
    _retryAfter = _now().add(refreshRetryDelay);
    return token;
  }
}
