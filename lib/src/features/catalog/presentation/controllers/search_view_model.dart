import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';

enum SearchSortOption { popular, newest, priceAsc, priceDesc }

class SearchState {
  const SearchState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.query = '',
    this.sort = SearchSortOption.popular,
    this.products = const [],
    this.page = 1,
    this.total = 0,
  });

  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String query;
  final SearchSortOption sort;
  final List<Product> products;
  final int page;
  final int total;

  bool get hasMore => products.length < total;

  List<Product> get sortedProducts {
    final list = [...products];
    switch (sort) {
      case SearchSortOption.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
      case SearchSortOption.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
      case SearchSortOption.newest:
        list.sort((a, b) => b.id.compareTo(a.id));
      case SearchSortOption.popular:
        break;
    }
    return list;
  }

  SearchState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    String? query,
    SearchSortOption? sort,
    List<Product>? products,
    int? page,
    int? total,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      query: query ?? this.query,
      sort: sort ?? this.sort,
      products: products ?? this.products,
      page: page ?? this.page,
      total: total ?? this.total,
    );
  }
}

class SearchViewModel extends Notifier<SearchState> {
  static const _pageSize = 16;

  @override
  SearchState build() => const SearchState();

  Future<void> search(String raw) async {
    final query = raw.trim();
    state = state.copyWith(isLoading: true, clearError: true, query: query);
    try {
      final result = await ref
          .read(catalogRepositoryProvider)
          .getProductsPage(
            search: query.isEmpty ? null : query,
            page: 1,
            limit: _pageSize,
          );
      state = state.copyWith(
        isLoading: false,
        page: 1,
        products: result.products,
        total: result.total,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString().replaceFirst('Exception: ', ''),
        products: const [],
        total: 0,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final result = await ref
          .read(catalogRepositoryProvider)
          .getProductsPage(
            search: state.query.isEmpty ? null : state.query,
            page: nextPage,
            limit: _pageSize,
          );
      state = state.copyWith(
        isLoadingMore: false,
        page: nextPage,
        total: result.total,
        products: [...state.products, ...result.products],
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void setSort(SearchSortOption value) {
    state = state.copyWith(sort: value);
  }
}
