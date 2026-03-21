import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/features/notifications/domain/models/app_notification.dart';

class NotificationsState {
  const NotificationsState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.notifications = const [],
    this.page = 1,
    this.total = 0,
  });

  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<AppNotification> notifications;
  final int page;
  final int total;

  int get unreadCount => notifications.where((n) => !n.isRead).length;
  bool get hasMore => notifications.length < total;

  NotificationsState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    List<AppNotification>? notifications,
    int? page,
    int? total,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      notifications: notifications ?? this.notifications,
      page: page ?? this.page,
      total: total ?? this.total,
    );
  }
}

class NotificationsViewModel extends Notifier<NotificationsState> {
  static const _pageSize = 20;

  @override
  NotificationsState build() => const NotificationsState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await ref
          .read(notificationRepositoryProvider)
          .getMyNotifications(page: 1, limit: _pageSize);
      state = state.copyWith(
        isLoading: false,
        notifications: result.notifications,
        total: result.total,
        page: 1,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final result = await ref
          .read(notificationRepositoryProvider)
          .getMyNotifications(page: nextPage, limit: _pageSize);
      state = state.copyWith(
        isLoadingMore: false,
        page: nextPage,
        total: result.total,
        notifications: [...state.notifications, ...result.notifications],
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> markOneAsRead(String id) async {
    try {
      await ref.read(notificationRepositoryProvider).markAsRead(id);
      state = state.copyWith(
        notifications: state.notifications
            .map(
              (n) => n.id == id
                  ? n.copyWith(isRead: true, readAt: DateTime.now())
                  : n,
            )
            .toList(),
      );
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await ref.read(notificationRepositoryProvider).markAllAsRead();
      state = state.copyWith(
        notifications: state.notifications
            .map((n) => n.copyWith(isRead: true, readAt: DateTime.now()))
            .toList(),
      );
    } catch (_) {}
  }
}
