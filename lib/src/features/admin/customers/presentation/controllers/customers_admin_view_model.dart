import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/customers/domain/models/admin_customer.dart';
import 'package:bakery_mobile/src/shared/utils/error_message.dart';

/// Filter-chip value meaning "no member-level filter" (chip 'Tất cả').
const String allLevelsFilter = 'ALL';

/// Immutable UI state for the admin customers list.
class CustomersAdminState {
  const CustomersAdminState({
    this.items = const [],
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
    this.search = '',
    this.levelFilter,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  /// Customers of every page loaded so far (pages 1..[page]).
  final List<AdminCustomer> items;

  /// Last page loaded.
  final int page;
  final int totalPages;

  /// Customers matching the current search + filter, across all pages.
  final int total;

  /// Trimmed search query sent to the server ('' = no search).
  final String search;

  /// Uppercase member-level filter (e.g. `GOLD`); null = all levels.
  final String? levelFilter;

  /// True while page 1 is being (re)loaded.
  final bool isLoading;

  /// True while the next page is being fetched.
  final bool isLoadingMore;

  /// Failure message of the last load / load-more; null otherwise.
  final String? error;

  bool get hasMore => page < totalPages;

  CustomersAdminState copyWith({
    List<AdminCustomer>? items,
    int? page,
    int? totalPages,
    int? total,
    String? search,
    String? levelFilter,
    bool clearLevelFilter = false,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return CustomersAdminState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      search: search ?? this.search,
      levelFilter: clearLevelFilter ? null : (levelFilter ?? this.levelFilter),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Drives the admin customers list: search, member-level filter, infinite
/// scroll and pull-to-refresh. A 401 logs the admin out (AppGate then shows
/// login) instead of surfacing an error.
class CustomersAdminViewModel extends Notifier<CustomersAdminState> {
  /// Bumped by every [load]; responses of superseded requests (e.g. an older
  /// search still in flight) are dropped so they never overwrite newer ones.
  int _generation = 0;

  @override
  CustomersAdminState build() => const CustomersAdminState();

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
          .read(customersAdminRepositoryProvider)
          .getCustomers(
            page: 1,
            search: state.search.isEmpty ? null : state.search,
            level: state.levelFilter,
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

  /// Sets the member-level filter and reloads from page 1; [level] is a
  /// filter-chip value — [allLevelsFilter] clears the filter, anything else
  /// is sent to the server as-is.
  Future<void> setFilter(String level) async {
    final value = level == allLevelsFilter ? null : level;
    if (value == state.levelFilter) return;
    state = state.copyWith(
      levelFilter: value,
      clearLevelFilter: value == null,
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
          .read(customersAdminRepositoryProvider)
          .getCustomers(
            page: nextPage,
            search: state.search.isEmpty ? null : state.search,
            level: state.levelFilter,
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
      error: userErrorMessage(error),
    );
  }
}

/// Note: unlike most VM providers (centralised in `core/di/app_providers.dart`)
/// this one lives next to its VM — the Task 2 file list allows touching only
/// the customers feature files.
final customersAdminViewModelProvider =
    NotifierProvider<CustomersAdminViewModel, CustomersAdminState>(
      CustomersAdminViewModel.new,
    );
