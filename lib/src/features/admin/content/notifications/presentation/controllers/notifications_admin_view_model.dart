import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/content/notifications/domain/models/admin_notification.dart';
import 'package:bakery_mobile/src/shared/utils/error_message.dart';

class NotificationsAdminState {
  const NotificationsAdminState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.isSaving = false,
    this.statusFilter,
  });

  final List<AdminNotification> items;
  final bool isLoading;
  final String? error;
  final bool isSaving;

  /// Wire status (DRAFT/PUBLISHED/ARCHIVED) or null for all.
  final String? statusFilter;

  NotificationsAdminState copyWith({
    List<AdminNotification>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isSaving,
    String? statusFilter,
    bool clearFilter = false,
  }) {
    return NotificationsAdminState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSaving: isSaving ?? this.isSaving,
      statusFilter: clearFilter ? null : (statusFilter ?? this.statusFilter),
    );
  }
}

/// Drives the Notifications admin screen: paged list, server-side search,
/// status chip filter, create (DRAFT by default).
class NotificationsAdminViewModel extends Notifier<NotificationsAdminState> {
  @override
  NotificationsAdminState build() => const NotificationsAdminState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(notificationAdminRepositoryProvider);
    try {
      final page = await repo.getNotifications(
        search: state.statusFilter == null ? _pendingSearch : null,
        status: state.statusFilter,
      );
      state = state.copyWith(items: page.items, isLoading: false);
      _pendingSearch = null;
    } catch (error) {
      if (await _logoutOn401(error)) {
        state = state.copyWith(isLoading: false);
        return;
      }
      state = state.copyWith(isLoading: false, error: _message(error));
    }
  }

  String? _pendingSearch;

  Future<void> setSearch(String text) async {
    _pendingSearch = text.trim().isEmpty ? null : text.trim();
    await load();
  }

  Future<void> setStatusFilter(String? status) async {
    state = state.copyWith(
      statusFilter: status,
      clearFilter: status == null,
    );
    await load();
  }

  /// Creates a notification; gates an empty title/content client-side.
  Future<bool> create({
    required String title,
    required String content,
    String? imageUrl,
    String? linkUrl,
    String status = 'DRAFT',
  }) async {
    if (title.trim().isEmpty) {
      state = state.copyWith(error: 'Tiêu đề không được để trống');
      return false;
    }
    if (content.trim().isEmpty) {
      state = state.copyWith(error: 'Nội dung không được để trống');
      return false;
    }
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    final repo = ref.read(notificationAdminRepositoryProvider);
    try {
      await repo.createNotification({
        'title': title.trim(),
        'content': content.trim(),
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (linkUrl != null && linkUrl.trim().isNotEmpty)
          'linkUrl': linkUrl.trim(),
        'status': status,
      });
      await load();
      state = state.copyWith(isSaving: false);
      return true;
    } catch (error) {
      if (await _logoutOn401(error)) {
        state = state.copyWith(isSaving: false);
        return false;
      }
      state = state.copyWith(isSaving: false, error: _message(error));
      return false;
    }
  }

  Future<bool> _logoutOn401(Object error) async {
    if (error is ApiException && error.statusCode == 401) {
      await ref.read(authViewModelProvider.notifier).logout();
      return true;
    }
    return false;
  }

  String _message(Object error) => userErrorMessage(error);
}

final notificationsAdminViewModelProvider =
    NotifierProvider<NotificationsAdminViewModel, NotificationsAdminState>(
      NotificationsAdminViewModel.new,
    );
