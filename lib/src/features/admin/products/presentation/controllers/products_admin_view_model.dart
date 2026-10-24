import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/categories/domain/models/admin_category.dart';
import 'package:bakery_mobile/src/features/admin/products/domain/models/admin_product.dart';
import 'package:bakery_mobile/src/shared/utils/error_message.dart';

/// Filter-chip value meaning "no status filter" (chip 'Tất cả').
const String allStatusesFilter = 'ALL';

/// Chip value showing only products on sale.
const String activeStatusFilter = 'active';

/// Chip value showing only paused products.
const String inactiveStatusFilter = 'inactive';

/// Immutable UI state for the admin products list.
class ProductsAdminState {
  const ProductsAdminState({
    this.items = const [],
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
    this.search = '',
    this.statusFilter,
    this.categoryFilter,
    this.categories = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.selectedIds = const {},
    this.isDeleting = false,
    this.report,
  });

  /// Products of every page loaded so far (pages 1..[page]), before the
  /// client-side status/category filters.
  final List<AdminProductListItem> items;

  /// Last page loaded.
  final int page;
  final int totalPages;

  /// Products matching the current search, across all pages.
  final int total;

  /// Trimmed search query sent to the server ('' = no search).
  final String search;

  /// Status filter ('active' / 'inactive'); null = all. Applied to the
  /// loaded items client-side — the server never sees it.
  final String? statusFilter;

  /// Category id filter; null = all categories. Also client-side, matched
  /// against each product's [AdminProductListItem.categoryIds].
  final String? categoryFilter;

  /// All categories flattened depth-first, for the dropdown.
  final List<AdminCategoryNode> categories;

  /// True while page 1 is being (re)loaded.
  final bool isLoading;

  /// True while the next page is being fetched.
  final bool isLoadingMore;

  /// Failure message of the last load / load-more; null otherwise.
  final String? error;

  /// Ids of the products selected for bulk deletion. A non-empty set means
  /// the screen is in selection mode.
  final Set<String> selectedIds;

  /// True while the selected products are being deleted.
  final bool isDeleting;

  /// Outcome of the last bulk delete, e.g. `Đã xóa 2 sản phẩm, 1 lỗi`.
  final String? report;

  bool get hasMore => page < totalPages;

  /// Whether the screen is in multi-select (bulk delete) mode.
  bool get isSelecting => selectedIds.isNotEmpty;

  /// [items] narrowed by the client-side status + category filters — the
  /// list the screen renders.
  List<AdminProductListItem> get visibleItems {
    var result = items;
    final status = statusFilter;
    if (status != null) {
      final showActive = status == activeStatusFilter;
      result = result.where((p) => p.isActive == showActive).toList();
    }
    final category = categoryFilter;
    if (category != null) {
      result = result.where((p) => p.categoryIds.contains(category)).toList();
    }
    return result;
  }

  ProductsAdminState copyWith({
    List<AdminProductListItem>? items,
    int? page,
    int? totalPages,
    int? total,
    String? search,
    String? statusFilter,
    bool clearStatusFilter = false,
    String? categoryFilter,
    bool clearCategoryFilter = false,
    List<AdminCategoryNode>? categories,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    Set<String>? selectedIds,
    bool? isDeleting,
    String? report,
    bool clearReport = false,
  }) {
    return ProductsAdminState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      total: total ?? this.total,
      search: search ?? this.search,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      categoryFilter: clearCategoryFilter
          ? null
          : (categoryFilter ?? this.categoryFilter),
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      selectedIds: selectedIds ?? this.selectedIds,
      isDeleting: isDeleting ?? this.isDeleting,
      report: clearReport ? null : (report ?? this.report),
    );
  }
}

/// Drives the admin products list: server-side search, client-side status
/// and category filters (both reset to page 1), infinite scroll,
/// pull-to-refresh and multi-select bulk delete. A 401 logs the admin out
/// (AppGate then shows login) instead of surfacing an error.
class ProductsAdminViewModel extends Notifier<ProductsAdminState> {
  /// Bumped by every [load]; responses of superseded requests (e.g. an older
  /// search still in flight) are dropped so they never overwrite newer ones.
  int _generation = 0;

  @override
  ProductsAdminState build() => const ProductsAdminState();

  /// (Re)loads page 1 for the current search. Already-loaded items stay
  /// visible while refreshing.
  Future<void> load() async {
    final generation = ++_generation;
    state = state.copyWith(
      isLoading: true,
      isLoadingMore: false,
      clearError: true,
    );
    try {
      final result = await ref
          .read(productsAdminRepositoryProvider)
          .getProducts(
            page: 1,
            search: state.search.isEmpty ? null : state.search,
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

  /// Sets the status filter chip ('active' / 'inactive') and reloads from
  /// page 1 — the filter itself is applied client-side to the loaded items
  /// (see [ProductsAdminState.visibleItems]); [allStatusesFilter] clears it.
  Future<void> setStatusFilter(String value) async {
    final status = value == allStatusesFilter ? null : value;
    if (status == state.statusFilter) return;
    state = state.copyWith(
      statusFilter: status,
      clearStatusFilter: status == null,
      items: const [],
    );
    await load();
  }

  /// Sets the category filter (a category id, null clears it) and reloads
  /// from page 1 — like the status filter it is applied client-side.
  Future<void> setCategory(String? categoryId) async {
    if (categoryId == state.categoryFilter) return;
    state = state.copyWith(
      categoryFilter: categoryId,
      clearCategoryFilter: categoryId == null,
      items: const [],
    );
    await load();
  }

  /// Loads the category tree (flattened) for the filter dropdown. Failures
  /// are swallowed: the dropdown stays at 'Tất cả danh mục' and the product
  /// list is unaffected (its own load surfaces errors, including 401).
  Future<void> loadCategories() async {
    try {
      final tree = await ref
          .read(categoriesAdminRepositoryProvider)
          .getCategories();
      state = state.copyWith(categories: AdminCategoryNode.flattenAll(tree));
    } catch (_) {
      // Dropdown-only concern — never block the products list on it.
    }
  }

  /// Appends the next page; no-op when there is none or a load is running.
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading || state.isLoadingMore) return;
    final generation = _generation;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final nextPage = state.page + 1;
      final result = await ref
          .read(productsAdminRepositoryProvider)
          .getProducts(
            page: nextPage,
            search: state.search.isEmpty ? null : state.search,
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

  /// Adds [id] to (or removes it from) the selection; selecting the first
  /// product enters selection mode, deselecting the last one exits it.
  Future<void> toggleSelect(String id) async {
    final selection = {...state.selectedIds};
    if (!selection.remove(id)) selection.add(id);
    state = state.copyWith(selectedIds: selection);
  }

  /// Leaves selection mode without deleting (the bar's X).
  Future<void> clearSelection() async {
    if (state.selectedIds.isEmpty) return;
    state = state.copyWith(selectedIds: const {});
  }

  /// Deletes every selected product one by one, then reloads the list. Each
  /// failure (e.g. a 404 `Không tìm thấy sản phẩm`) is counted — never
  /// thrown — and summarised in [ProductsAdminState.report]. A 401 logs the
  /// admin out and aborts the remaining deletions.
  Future<void> bulkDelete() async {
    final ids = state.selectedIds.toList();
    if (ids.isEmpty || state.isDeleting) return;
    state = state.copyWith(isDeleting: true, clearReport: true);
    var ok = 0;
    var failed = 0;
    for (final id in ids) {
      try {
        await ref.read(productsAdminRepositoryProvider).deleteProduct(id);
        ok++;
      } catch (error) {
        if (error is ApiException && error.statusCode == 401) {
          state = state.copyWith(isDeleting: false, selectedIds: const {});
          await ref.read(authViewModelProvider.notifier).logout();
          return;
        }
        failed++;
      }
    }
    state = state.copyWith(
      isDeleting: false,
      selectedIds: const {},
      report: failed == 0
          ? 'Đã xóa $ok sản phẩm'
          : 'Đã xóa $ok sản phẩm, $failed lỗi',
    );
    await load();
  }

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
/// this one lives next to its VM — the Task 3 file list allows touching only
/// the products feature files.
final productsAdminViewModelProvider =
    NotifierProvider<ProductsAdminViewModel, ProductsAdminState>(
      ProductsAdminViewModel.new,
    );
