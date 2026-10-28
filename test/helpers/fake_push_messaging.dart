import 'dart:async';

import 'package:bakery_mobile/src/core/push/push_messaging.dart';

/// In-memory FCM: tests drive tokens, permission and incoming messages.
class FakePushMessaging implements PushMessaging {
  FakePushMessaging({this.token = 'token-1', this.allowNotifications = true});

  String? token;
  bool allowNotifications;
  PushMessage? launchMessage;

  final List<String> topics = [];
  int permissionRequests = 0;
  int deletedTokens = 0;

  /// Token handed out after [deleteToken].
  String nextToken = 'token-fresh';

  // Synchronous, so an event reaches the app inside the test's fake clock
  // (the controllers are created in setUp, outside it).
  final _refresh = StreamController<String>.broadcast(sync: true);
  final _foreground = StreamController<PushMessage>.broadcast(sync: true);
  final _opened = StreamController<PushMessage>.broadcast(sync: true);

  void rotateToken(String value) {
    token = value;
    _refresh.add(value);
  }

  void receive(PushMessage message) => _foreground.add(message);
  void tap(PushMessage message) => _opened.add(message);

  @override
  bool get isAvailable => true;

  @override
  Future<bool> requestPermission() async {
    permissionRequests += 1;
    return allowNotifications;
  }

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => _refresh.stream;

  @override
  Future<void> deleteToken() async {
    deletedTokens += 1;
    token = nextToken;
  }

  @override
  Future<void> subscribeToTopic(String topic) async => topics.add(topic);

  @override
  Stream<PushMessage> get onForegroundMessage => _foreground.stream;

  @override
  Stream<PushMessage> get onMessageOpenedApp => _opened.stream;

  @override
  Future<PushMessage?> getInitialMessage() async => launchMessage;
}
