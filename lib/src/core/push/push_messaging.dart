import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// A push notification as the app uses it, free of Firebase types.
class PushMessage {
  const PushMessage({this.title, this.body, this.data = const {}});

  final String? title;
  final String? body;

  /// Sent by bakery-web: `eventType`, `entityId`, and `orderNumber` for
  /// order updates.
  final Map<String, String> data;

  String? get orderNumber {
    final value = data['orderNumber']?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}

/// The push channel (FCM). [DisabledPushMessaging] stands in when this build
/// has no Firebase config, so the rest of the app never checks for it.
abstract class PushMessaging {
  bool get isAvailable;

  /// Asks the user to allow notifications (Android 13+, iOS). True when
  /// notifications may be shown.
  Future<bool> requestPermission();

  Future<String?> getToken();
  Stream<String> get onTokenRefresh;

  /// Drops this install's token, so the next [getToken] returns a new one.
  Future<void> deleteToken();

  Future<void> subscribeToTopic(String topic);

  /// Messages that arrive while the app is open (the system shows nothing).
  Stream<PushMessage> get onForegroundMessage;

  /// Notifications tapped while the app was in the background.
  Stream<PushMessage> get onMessageOpenedApp;

  /// The notification tapped to launch the app from closed, if any.
  Future<PushMessage?> getInitialMessage();
}

class DisabledPushMessaging implements PushMessaging {
  const DisabledPushMessaging();

  @override
  bool get isAvailable => false;
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<String?> getToken() async => null;
  @override
  Stream<String> get onTokenRefresh => const Stream.empty();
  @override
  Future<void> deleteToken() async {}
  @override
  Future<void> subscribeToTopic(String topic) async {}
  @override
  Stream<PushMessage> get onForegroundMessage => const Stream.empty();
  @override
  Stream<PushMessage> get onMessageOpenedApp => const Stream.empty();
  @override
  Future<PushMessage?> getInitialMessage() async => null;
}

/// Uses classic FCM registration tokens (getToken / onTokenRefresh /
/// deleteToken), deprecated in firebase_messaging 17 for Installation-ID
/// targets: bakery-web sends with firebase-admin's token multicast, so the
/// two sides move to Installation IDs together or not at all.
class FirebasePushMessaging implements PushMessaging {
  FirebasePushMessaging(this._messaging);

  final FirebaseMessaging _messaging;

  static PushMessage _toMessage(RemoteMessage message) => PushMessage(
    title: message.notification?.title,
    body: message.notification?.body,
    data: message.data.map((key, value) => MapEntry(key, '$value')),
  );

  @override
  bool get isAvailable => true;

  @override
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  // ignore: deprecated_member_use
  Future<String?> getToken() => _messaging.getToken();

  @override
  // ignore: deprecated_member_use
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  // ignore: deprecated_member_use
  Future<void> deleteToken() => _messaging.deleteToken();

  @override
  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);

  @override
  Stream<PushMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage.map(_toMessage);

  @override
  Stream<PushMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp.map(_toMessage);

  @override
  Future<PushMessage?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _toMessage(message);
  }
}

/// Starts Firebase for push. Without a Firebase config in this build
/// (android/app/google-services.json, see docs/push-notifications.md) the
/// app runs on with push turned off instead of failing to start.
Future<PushMessaging> initPushMessaging() async {
  try {
    await Firebase.initializeApp();
    return FirebasePushMessaging(FirebaseMessaging.instance);
  } catch (error) {
    debugPrint('Push notifications off: $error');
    return const DisabledPushMessaging();
  }
}
