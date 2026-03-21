import 'package:flutter/foundation.dart';

import 'package:bakery_mobile/src/features/notifications/domain/models/app_notification.dart';
import 'package:bakery_mobile/src/features/notifications/data/repositories/notification_repository.dart';

class NotificationsViewModel extends ChangeNotifier {
  NotificationsViewModel(this._notificationRepository);

  final NotificationRepository _notificationRepository;
  static const _pageSize = 20;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  List<AppNotification> _notifications = [];
  int _page = 1;
  int _total = 0;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get hasMore => _notifications.length < _total;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _notificationRepository.getMyNotifications(
        page: 1,
        limit: _pageSize,
      );
      _notifications = result.notifications;
      _total = result.total;
      _page = 1;
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !hasMore) return;

    _isLoadingMore = true;
    notifyListeners();
    try {
      final nextPage = _page + 1;
      final result = await _notificationRepository.getMyNotifications(
        page: nextPage,
        limit: _pageSize,
      );
      _page = nextPage;
      _total = result.total;
      _notifications = [..._notifications, ...result.notifications];
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> markOneAsRead(String id) async {
    try {
      await _notificationRepository.markAsRead(id);
      _notifications = _notifications
          .map(
            (n) => n.id == id
                ? n.copyWith(isRead: true, readAt: DateTime.now())
                : n,
          )
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _notificationRepository.markAllAsRead();
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
          .toList();
      notifyListeners();
    } catch (_) {}
  }
}


