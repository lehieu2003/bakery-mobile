import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/audit/domain/models/audit_models.dart';
import 'package:bakery_mobile/src/shared/utils/error_message.dart';

class AuditAdminState {
  const AuditAdminState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.totalPages = 1,
    this.isLoadingMore = false,
  });

  final List<AuditLogRow> items;
  final bool isLoading;
  final String? error;
  final int page;
  final int totalPages;
  final bool isLoadingMore;

  bool get canLoadMore => page < totalPages && !isLoadingMore;

  AuditAdminState copyWith({
    List<AuditLogRow>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
  }) {
    return AuditAdminState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Drives the "Nhật ký hệ thống" screen: paged audit log with
/// load-more (server pagination contract: page/limit/totalPages).
class AuditAdminViewModel extends Notifier<AuditAdminState> {
  @override
  AuditAdminState build() => const AuditAdminState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true, page: 1);
    final repo = ref.read(auditAdminRepositoryProvider);
    try {
      final result = await repo.getAudit(page: 1);
      state = state.copyWith(
        items: result.items,
        totalPages: result.totalPages,
        isLoading: false,
      );
    } catch (error) {
      if (await _logoutOn401(error)) {
        state = state.copyWith(isLoading: false);
        return;
      }
      state = state.copyWith(isLoading: false, error: _message(error));
    }
  }

  Future<void> loadMore() async {
    if (!state.canLoadMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    final repo = ref.read(auditAdminRepositoryProvider);
    try {
      final nextPage = state.page + 1;
      final result = await repo.getAudit(page: nextPage);
      state = state.copyWith(
        items: [...state.items, ...result.items],
        page: nextPage,
        totalPages: result.totalPages,
        isLoadingMore: false,
      );
    } catch (error) {
      if (await _logoutOn401(error)) {
        state = state.copyWith(isLoadingMore: false);
        return;
      }
      state = state.copyWith(isLoadingMore: false, error: _message(error));
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

final auditAdminViewModelProvider =
    NotifierProvider<AuditAdminViewModel, AuditAdminState>(
      AuditAdminViewModel.new,
    );
