import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/banner_item.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/category.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';

class HomeState {
  const HomeState({
    this.isLoading = false,
    this.errorMessage,
    this.banners = const [],
    this.categories = const [],
    this.bestSellers = const [],
    this.products = const [],
    this.selectedCategoryId,
    this.search = '',
  });

  final bool isLoading;
  final String? errorMessage;
  final List<BannerItem> banners;
  final List<Category> categories;
  final List<Product> bestSellers;
  final List<Product> products;
  final String? selectedCategoryId;
  final String search;

  HomeState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<BannerItem>? banners,
    List<Category>? categories,
    List<Product>? bestSellers,
    List<Product>? products,
    String? selectedCategoryId,
    bool clearCategory = false,
    String? search,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      banners: banners ?? this.banners,
      categories: categories ?? this.categories,
      bestSellers: bestSellers ?? this.bestSellers,
      products: products ?? this.products,
      selectedCategoryId: clearCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      search: search ?? this.search,
    );
  }
}

class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() => const HomeState();

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repo = ref.read(catalogRepositoryProvider);
      final results = await Future.wait([
        repo.getBanners(),
        repo.getCategories(),
        repo.getBestSellers(),
        repo.getProducts(),
      ]);

      state = state.copyWith(
        isLoading: false,
        banners: results[0] as List<BannerItem>,
        categories: results[1] as List<Category>,
        bestSellers: results[2] as List<Product>,
        products: results[3] as List<Product>,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> search(String value) async {
    state = state.copyWith(search: value.trim());
    await _reloadProducts();
  }

  Future<void> selectCategory(String? categoryId) async {
    state = state.copyWith(
      selectedCategoryId: categoryId,
      clearCategory: categoryId == null,
    );
    await _reloadProducts();
  }

  Future<void> _reloadProducts() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final products = await ref
          .read(catalogRepositoryProvider)
          .getProducts(
            categoryId: state.selectedCategoryId,
            search: state.search,
          );
      state = state.copyWith(isLoading: false, products: products);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}
