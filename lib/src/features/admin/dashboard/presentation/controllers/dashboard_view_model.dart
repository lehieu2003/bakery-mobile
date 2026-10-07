import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/dashboard/domain/models/dashboard_stats.dart';

/// Immutable UI state for the admin dashboard screen.
class DashboardState {
  const DashboardState({
    this.stats,
    this.isLoading = false,
    this.error,
    this.windowDays = 7,
  });

  /// Aggregated KPI/chart/recent-order stats for the current window; null
  /// until the first successful load.
  final DashboardStats? stats;

  /// True while a fetch is in flight (initial load, window switch, or a
  /// background polling tick).
  final bool isLoading;

  /// Failure message of the last load (from `ApiException.message`); null
  /// after a successful load or when cleared by a new load starting.
  final String? error;

  /// Trailing window, in days, the stats are fetched for (7 or 30).
  final int windowDays;

  DashboardState copyWith({
    DashboardStats? stats,
    bool clearStats = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? windowDays,
  }) {
    return DashboardState(
      stats: clearStats ? null : (stats ?? this.stats),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      windowDays: windowDays ?? this.windowDays,
    );
  }
}

/// Drives the admin dashboard: initial fetch, window switching (7/30 days)
/// and a 5-minute polling loop that keeps the KPIs fresh while the screen
/// is mounted.
class DashboardViewModel extends Notifier<DashboardState> {
  Timer? _refreshTimer;

  @override
  DashboardState build() {
    // The polling timer must never outlive the provider — cancelling on
    // dispose keeps closed screens (and test containers) from leaking a
    // periodic timer that keeps firing forever.
    ref.onDispose(_stopAutoRefresh);
    return const DashboardState();
  }

  /// Fetches the stats for the currently selected [DashboardState.windowDays].
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final stats = await ref
          .read(dashboardRepositoryProvider)
          .getStats(windowDays: state.windowDays);
      state = state.copyWith(stats: stats, isLoading: false, clearError: true);
    } on ApiException catch (error) {
      // Keep the stale stats on screen (clearStats stays false) so a failed
      // background refresh never blanks an already-loaded dashboard.
      state = state.copyWith(error: error.message, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        error: error.toString().replaceFirst('Exception: ', ''),
        isLoading: false,
      );
    }
  }

  /// Switches the trailing window (e.g. 7 → 30 days) and reloads.
  Future<void> setWindow(int windowDays) async {
    state = state.copyWith(windowDays: windowDays);
    await load();
  }

  /// Starts a refresh loop that reloads the stats every 5 minutes. Calling
  /// it again cancels the previous timer first, so exactly one loop is ever
  /// alive; [ref.onDispose] cancels it when the provider goes away.
  void startAutoRefresh() {
    _stopAutoRefresh();
    _refreshTimer = Timer.periodic(const Duration(seconds: 300), (_) {
      load();
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }
}
