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
    this.filters = const ProductFilters(),
    this.selectedAttributeFilters = const [],
    this.minPrice,
    this.maxPrice,
    this.inStock,
    this.products = const [],
    this.page = 1,
    this.total = 0,
  });

  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String query;
  final SearchSortOption sort;
  final ProductFilters filters;
  final List<ProductAttributeFilter> selectedAttributeFilters;
  final double? minPrice;
  final double? maxPrice;
  final bool? inStock;
  final List<Product> products;
  final int page;
  final int total;

  bool get hasMore => products.length < total;
  bool get hasActiveFilters =>
      minPrice != null ||
      maxPrice != null ||
      inStock == true ||
      selectedAttributeFilters.isNotEmpty;

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
    ProductFilters? filters,
    List<ProductAttributeFilter>? selectedAttributeFilters,
    double? minPrice,
    bool clearMinPrice = false,
    double? maxPrice,
    bool clearMaxPrice = false,
    bool? inStock,
    bool clearInStock = false,
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
      filters: filters ?? this.filters,
      selectedAttributeFilters:
          selectedAttributeFilters ?? this.selectedAttributeFilters,
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      inStock: clearInStock ? null : (inStock ?? this.inStock),
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

  Future<void> loadFilters() async {
    try {
      final filters = await ref
          .read(catalogRepositoryProvider)
          .getProductFilters();
      state = state.copyWith(filters: filters);
    } catch (_) {
      // Filters are enhancement-only; keep search usable if unavailable.
    }
  }

  Future<void> search(String raw) async {
    final query = raw.trim();
    state = state.copyWith(isLoading: true, clearError: true, query: query);
    try {
      final result = await ref
          .read(catalogRepositoryProvider)
          .getProductsPage(
            search: query.isEmpty ? null : query,
            minPrice: state.minPrice,
            maxPrice: state.maxPrice,
            inStock: state.inStock,
            attributeFilters: state.selectedAttributeFilters,
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
            minPrice: state.minPrice,
            maxPrice: state.maxPrice,
            inStock: state.inStock,
            attributeFilters: state.selectedAttributeFilters,
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

  Future<void> applyFilters({
    required List<ProductAttributeFilter> attributeFilters,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
  }) async {
    state = state.copyWith(
      selectedAttributeFilters: attributeFilters,
      minPrice: minPrice,
      clearMinPrice: minPrice == null,
      maxPrice: maxPrice,
      clearMaxPrice: maxPrice == null,
      inStock: inStock,
      clearInStock: inStock == null,
    );
    await search(state.query);
  }

  Future<void> clearFilters() {
    return applyFilters(attributeFilters: const []);
  }
}
