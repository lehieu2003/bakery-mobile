import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/customers/domain/models/admin_customer.dart';
import 'package:bakery_mobile/src/shared/utils/error_message.dart';

/// Immutable UI state for one admin customer detail screen.
class CustomerDetailState {
  const CustomerDetailState({
    this.detail,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.updateError,
  });

  /// Null until the first successful load.
  final AdminCustomerDetail? detail;

  /// True while the detail is being (re)loaded.
  final bool isLoading;

  /// True while a member-level/points PATCH is in flight.
  final bool isSaving;

  /// Failure of the detail load — the screen renders the retry state.
  final String? error;

  /// Failure of the last update — shown as a snackbar, the loaded detail
  /// stays on screen.
  final String? updateError;

  CustomerDetailState copyWith({
    AdminCustomerDetail? detail,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
    String? updateError,
    bool clearUpdateError = false,
  }) {
    return CustomerDetailState(
      detail: detail ?? this.detail,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      updateError: clearUpdateError ? null : (updateError ?? this.updateError),
    );
  }
}

/// Drives one admin customer detail (family key = customer id): detail load
/// and the member-level/points update consumed by the edit bottom sheet
/// (Task 4). A 401 logs the admin out instead of surfacing an error.
class CustomerDetailViewModel
    extends FamilyNotifier<CustomerDetailState, String> {
  @override
  CustomerDetailState build(String arg) => const CustomerDetailState();

  /// (Re)loads the customer's detail blocks: recent orders, payments,
  /// notifications and the notification summary.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(customersAdminRepositoryProvider);
    try {
      final detail = await repo.getCustomer(arg);
      state = state.copyWith(detail: detail, isLoading: false);
    } catch (error) {
      if (await _logoutOn401(error)) {
        state = state.copyWith(isLoading: false);
        return;
      }
      state = state.copyWith(isLoading: false, error: _message(error));
    }
  }

  /// Retries a failed [load].
  Future<void> retry() => load();

  /// Updates the customer's member level and/or points; only provided keys
  /// are sent. Returns true on success (the detail is replaced with the
  /// server's response); on failure [CustomerDetailState.updateError] is set.
  Future<bool> update({String? memberLevel, int? points}) async {
    if (state.isSaving) return false;
    // Client gate mirrors the server's integer >= 0 rule (400 'Invalid
    // points') so an impossible value never leaves the device.
    if (points != null && points < 0) {
      state = state.copyWith(updateError: 'Điểm phải là số nguyên không âm');
      return false;
    }
    state = state.copyWith(isSaving: true, clearUpdateError: true);
    final repo = ref.read(customersAdminRepositoryProvider);
    try {
      final updated = await repo.updateCustomer(
        arg,
        memberLevel: memberLevel,
        points: points,
      );
      // The PATCH response is a stripped customer (no stats/recents) —
      // re-fetch the full detail so the screen keeps its numbers.
      assert(updated.id == arg);
      final detail = await repo.getCustomer(arg);
      state = state.copyWith(detail: detail, isSaving: false);
      return true;
    } catch (error) {
      if (await _logoutOn401(error)) {
        state = state.copyWith(isSaving: false);
        return false;
      }
      state = state.copyWith(isSaving: false, updateError: _message(error));
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

/// Note: unlike most VM providers (centralised in `core/di/app_providers.dart`)
/// this one lives next to its VM — the Task 3 file list allows touching only
/// the customers feature files.
final customerDetailViewModelProvider =
    NotifierProvider.family<
      CustomerDetailViewModel,
      CustomerDetailState,
      String
    >(CustomerDetailViewModel.new);
