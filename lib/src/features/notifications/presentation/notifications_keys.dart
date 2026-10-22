import 'package:flutter/widgets.dart';

/// Widget keys of the notifications screen (used by tests and finders).
abstract final class NotificationsKeys {
  static const loading = Key('notifications.loading');
  static const list = Key('notifications.list');
  static const empty = Key('notifications.empty');
  static const error = Key('notifications.error');
  static const loadMore = Key('notifications.loadMore');
  static const markAllRead = Key('notifications.markAllRead');

  static Key item(String id) => Key('notifications.item.$id');
  static Key markRead(String id) => Key('notifications.markRead.$id');
}
