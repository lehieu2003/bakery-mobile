import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/orders/domain/models/admin_order.dart';
import 'package:bakery_mobile/src/features/admin/orders/domain/models/order_audit.dart';

/// Immutable UI state for one admin order detail screen.
class OrderDetailState {
  const OrderDetailState({
    this.order,
    this.audit,
    this.investigation,
    this.isLoading = false,
    this.isUpdating = false,
    this.isLoadingInvestigation = false,
    this.error,
    this.updateError,
    this.investigationError,
  });

  /// Null until the first successful load.
  final AdminOrder? order;

  /// First page of the audit trail; null until loaded.
  final List<OrderAuditLog>? audit;

  /// Payment investigation — loaded lazily by [OrderDetailViewModel.loadInvestigation].
  final OrderInvestigation? investigation;

  final bool isLoading;

  /// True while a status PATCH is in flight (disables the transition chips).
  final bool isUpdating;
  final bool isLoadingInvestigation;

  /// Failure of the order/audit load.
  final String? error;

  /// Failure of the last status update — shown as a snackbar, the loaded
  /// order stays on screen.
  final String? updateError;
  final String? investigationError;

  OrderDetailState copyWith({
    AdminOrder? order,
    List<OrderAuditLog>? audit,
    OrderInvestigation? investigation,
    bool? isLoading,
    bool? isUpdating,
    bool? isLoadingInvestigation,
    String? error,
    bool clearError = false,
    String? updateError,
    bool clearUpdateError = false,
    String? investigationError,
    bool clearInvestigationError = false,
  }) {
    return OrderDetailState(
      order: order ?? this.order,
      audit: audit ?? this.audit,
      investigation: investigation ?? this.investigation,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      isLoadingInvestigation:
          isLoadingInvestigation ?? this.isLoadingInvestigation,
      error: clearError ? null : (error ?? this.error),
      updateError: clearUpdateError ? null : (updateError ?? this.updateError),
      investigationError: clearInvestigationError
          ? null
          : (investigationError ?? this.investigationError),
    );
  }
}

/// Drives the admin order detail (family key = order id or order number):
/// order + audit load, status transitions (with cancel reason) and the lazy
/// payment investigation. A 401 logs the admin out instead of erroring.
class OrderDetailViewModel extends FamilyNotifier<OrderDetailState, String> {
  @override
  OrderDetailState build(String arg) => const OrderDetailState();

  /// Loads the order and the first audit page in parallel.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(ordersAdminRepositoryProvider);
    try {
      final results = await Future.wait([
        repo.getOrder(arg),
        repo.getOrderAudit(arg),
      ]);
      final audit = results[1] as ({List<OrderAuditLog> logs, int totalPages});
      state = state.copyWith(
        order: results[0] as AdminOrder,
        audit: audit.logs,
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

  /// Moves the order to [next] (server re-validates the transition);
  /// [notes] is the cancellation reason, stored in the audit metadata.
  /// Returns true on success; on failure [OrderDetailState.updateError] is set.
  Future<bool> updateStatus(String next, {String? notes}) async {
    if (state.isUpdating) return false;
    state = state.copyWith(isUpdating: true, clearUpdateError: true);
    final repo = ref.read(ordersAdminRepositoryProvider);
    try {
      final updated = await repo.updateOrder(arg, status: next, notes: notes);
      state = state.copyWith(order: updated, isUpdating: false);
    } catch (error) {
      if (await _logoutOn401(error)) {
        state = state.copyWith(isUpdating: false);
        return false;
      }
      state = state.copyWith(isUpdating: false, updateError: _message(error));
      return false;
    }
    // The new audit entry is best-effort: a failed refresh keeps the old list.
    try {
      final audit = await repo.getOrderAudit(arg);
      state = state.copyWith(audit: audit.logs);
    } catch (_) {}
    return true;
  }

  /// Loads the payment investigation (callback timeline + reconciliation).
  Future<void> loadInvestigation() async {
    if (state.isLoadingInvestigation) return;
    state = state.copyWith(
      isLoadingInvestigation: true,
      clearInvestigationError: true,
    );
    try {
      final investigation = await ref
          .read(ordersAdminRepositoryProvider)
          .getInvestigation(arg);
      state = state.copyWith(
        investigation: investigation,
        isLoadingInvestigation: false,
      );
    } catch (error) {
      if (await _logoutOn401(error)) {
        state = state.copyWith(isLoadingInvestigation: false);
        return;
      }
      state = state.copyWith(
        isLoadingInvestigation: false,
        investigationError: _message(error),
      );
    }
  }

  Future<bool> _logoutOn401(Object error) async {
    if (error is ApiException && error.statusCode == 401) {
      await ref.read(authViewModelProvider.notifier).logout();
      return true;
    }
    return false;
  }

  String _message(Object error) => error is ApiException
      ? error.message
      : error.toString().replaceFirst('Exception: ', '');
}
