import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/orders/domain/models/admin_order.dart';

/// Immutable UI state for the admin orders list.
class OrdersAdminState {
  const OrdersAdminState({
    this.items = const [],
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
    this.search = '',
    this.statusFilter,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  /// Orders of every page loaded so far (pages 1..[page]).
  final List<AdminOrder> items;

  /// Last page loaded.
  final int page;
  final int totalPages;

  /// Orders matching the current search + filter, across all pages.
  final int total;

  /// Trimmed search query sent to the server ('' = no search).
  final String search;

  /// Uppercase status filter; null = all statuses.
  final String? statusFilter;

  /// True while page 1 is being (re)loaded.
  final bool isLoading;

  /// True while the next page is being fetched.
  final bool isLoadingMore;

  /// Failure message of the last load / load-more; null otherwise.
  final String? error;

  bool get hasMore => page < totalPages;

  OrdersAdminState copyWith({
    List<AdminOrder>? items,
    int? page,
    int? totalPages,
    int? total,
    String? search,
    String? statusFilter,
    bool clearStatusFilter = false,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return OrdersAdminState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      search: search ?? this.search,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Drives the admin orders list: search, status filter, infinite scroll and
/// pull-to-refresh. A 401 logs the admin out (AppGate then shows login)
/// instead of surfacing an error.
class OrdersAdminViewModel extends Notifier<OrdersAdminState> {
  /// Bumped by every [load]; responses of superseded requests (e.g. an older
  /// search still in flight) are dropped so they never overwrite newer ones.
  int _generation = 0;

  @override
  OrdersAdminState build() => const OrdersAdminState();

  /// (Re)loads page 1 for the current search + filter. Already-loaded items
  /// stay visible while refreshing.
  Future<void> load() async {
    final generation = ++_generation;
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      clearError: true,
    );
    try {
      final result = await ref
          .read(ordersAdminRepositoryProvider)
          .getOrders(
            page: 1,
            search: state.search.isEmpty ? null : state.search,
            status: state.statusFilter,
          );
      if (generation != _generation) return;
      state = state.copyWith(
        items: result.items,
        page: 1,
        totalPages: result.totalPages,
        total: result.total,
        isLoading: false,
      );
    } catch (error) {
      if (generation != _generation) return;
      await _fail(error);
    }
  }

  /// Sets the search query (trimmed) and reloads from page 1; no-op when it
  /// is unchanged.
  Future<void> setSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed == state.search) return;
    state = state.copyWith(search: trimmed, items: const []);
    await load();
  }

  /// Sets the status filter (null = all) and reloads from page 1.
  Future<void> setStatusFilter(String? status) async {
    if (status == state.statusFilter) return;
    state = state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
      items: const [],
    );
    await load();
  }

  /// Appends the next page; no-op when there is none or a load is running.
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading || state.isLoadingMore) return;
    final generation = _generation;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final nextPage = state.page + 1;
      final result = await ref
          .read(ordersAdminRepositoryProvider)
          .getOrders(
            page: nextPage,
            search: state.search.isEmpty ? null : state.search,
            status: state.statusFilter,
          );
      if (generation != _generation) return;
      state = state.copyWith(
        items: [...state.items, ...result.items],
        page: nextPage,
        totalPages: result.totalPages,
        total: result.total,
        isLoadingMore: false,
      );
    } catch (error) {
      if (generation != _generation) return;
      await _fail(error);
    }
  }

  /// Swaps in [updated] (matched by id) after a change made on the detail
  /// screen, so the list reflects it without a reload. No-op when the order
  /// is not loaded. A status that no longer matches the active filter stays
  /// visible until the next load.
  void replaceOrder(AdminOrder updated) {
    final index = state.items.indexWhere((o) => o.id == updated.id);
    if (index < 0) return;
    final items = [...state.items]..[index] = updated;
    state = state.copyWith(items: items);
  }

  /// Retries whatever failed: the first page when nothing is shown yet,
  /// otherwise the next page.
  Future<void> retry() => state.items.isEmpty ? load() : loadMore();

  Future<void> _fail(Object error) async {
    if (error is ApiException && error.statusCode == 401) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        clearError: true,
      );
      await ref.read(authViewModelProvider.notifier).logout();
      return;
    }
    state = state.copyWith(
      isLoading: false,
      isLoadingMore: false,
      error: error is ApiException
          ? error.message
          : error.toString().replaceFirst('Exception: ', ''),
    );
  }
}
