import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';
import 'package:bakery_mobile/src/shared/utils/error_message.dart';

class CategoryState {
  const CategoryState({
    required this.selectedCategoryId,
    this.products = const [],
    this.total = 0,
    this.page = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  /// The category whose products are listed: the screen's root category
  /// ("Tất cả") or one of its subcategories.
  final String selectedCategoryId;
  final List<Product> products;
  final int total;
  final int page;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  bool get hasMore => products.length < total;

  CategoryState copyWith({
    String? selectedCategoryId,
    List<Product>? products,
    int? total,
    int? page,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return CategoryState(
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      products: products ?? this.products,
      total: total ?? this.total,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Products of one category (family arg: the root category id), newest
/// pages appended as the user scrolls. bakery-web's `categoryId` filter
/// already includes every descendant, so the root lists the whole tree.
class CategoryViewModel
    extends AutoDisposeFamilyNotifier<CategoryState, String> {
  static const _pageSize = 16;

  @override
  CategoryState build(String rootCategoryId) =>
      CategoryState(selectedCategoryId: rootCategoryId);

  /// Loads page 1 of [categoryId] (default: the current selection),
  /// replacing the list.
  Future<void> load([String? categoryId]) async {
    final selected = categoryId ?? state.selectedCategoryId;
    state = CategoryState(selectedCategoryId: selected, isLoading: true);
    try {
      final result = await ref
          .read(catalogRepositoryProvider)
          .getProductsPage(categoryId: selected, page: 1, limit: _pageSize);
      // A later selection wins; its answer must not be overwritten.
      if (state.selectedCategoryId != selected) return;
      state = state.copyWith(
        isLoading: false,
        page: 1,
        products: result.products,
        total: result.total,
      );
    } catch (error) {
      if (state.selectedCategoryId != selected) return;
      state = state.copyWith(isLoading: false, error: userErrorMessage(error));
    }
  }

  Future<void> select(String categoryId) async {
    if (categoryId == state.selectedCategoryId) return;
    await load(categoryId);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final selected = state.selectedCategoryId;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final nextPage = state.page + 1;
      final result = await ref
          .read(catalogRepositoryProvider)
          .getProductsPage(
            categoryId: selected,
            page: nextPage,
            limit: _pageSize,
          );
      if (state.selectedCategoryId != selected) return;
      state = state.copyWith(
        isLoadingMore: false,
        page: nextPage,
        total: result.total,
        products: [...state.products, ...result.products],
      );
    } catch (error) {
      if (state.selectedCategoryId != selected) return;
      state = state.copyWith(
        isLoadingMore: false,
        error: userErrorMessage(error),
      );
    }
  }
}
