import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/core/push/push_messaging.dart';
import 'package:bakery_mobile/src/features/notifications/data/datasources/device_token_api_service.dart';

/// FCM topic for shop-wide announcements; bakery-web's ANNOUNCEMENTS_TOPIC.
const announcementsTopic = 'announcements';

/// Links this install's push token to the signed-in account on bakery-web,
/// so order updates and announcements reach the phone. Push is a bonus:
/// nothing here throws to the caller.
class PushRegistrationService {
  PushRegistrationService({
    required PushMessaging messaging,
    required DeviceTokenApiService api,
    String? platform,
  }) : _messaging = messaging,
       _api = api,
       _platform = platform ?? defaultTargetPlatform.name;

  final PushMessaging _messaging;
  final DeviceTokenApiService _api;
  final String _platform;

  String? _registeredToken;
  StreamSubscription<String>? _tokenRefresh;

  /// After sign-in: joins announcements, asks to show notifications and
  /// registers the token (again whenever FCM rotates it).
  Future<void> register() async {
    if (!_messaging.isAvailable) return;
    try {
      await _messaging.subscribeToTopic(announcementsTopic);
      if (!await _messaging.requestPermission()) return;
      await _send(await _messaging.getToken());
      _tokenRefresh ??= _messaging.onTokenRefresh.listen(_send);
    } catch (error) {
      debugPrint('Push registration failed: $error');
    }
  }

  Future<void> _send(String? token) async {
    if (token == null || token.isEmpty) return;
    try {
      await _api.register(token: token, platform: _platform);
      _registeredToken = token;
    } on ApiException catch (error) {
      // The token is still tied to an account whose session ended here
      // without a sign-out. A fresh token cuts that account off this phone.
      if (error.statusCode != 409) rethrow;
      await _messaging.deleteToken();
      final fresh = await _messaging.getToken();
      if (fresh == null || fresh == token) return;
      await _api.register(token: fresh, platform: _platform);
      _registeredToken = fresh;
    }
  }

  /// Before sign-out, while the session still works: this phone stops
  /// getting the account's pushes.
  Future<void> unregister() async {
    final token = _registeredToken;
    forget();
    if (token == null) return;
    try {
      await _api.revoke(token);
    } catch (error) {
      debugPrint('Push token revoke failed: $error');
    }
  }

  /// The account is gone (deleted, or the session expired): stop tracking
  /// token changes. The server already dropped or will reject the token.
  void forget() {
    _tokenRefresh?.cancel();
    _tokenRefresh = null;
    _registeredToken = null;
  }
}
