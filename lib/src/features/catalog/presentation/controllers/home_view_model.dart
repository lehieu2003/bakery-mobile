import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/features/catalog/data/repositories/catalog_repository.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/banner_item.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/category.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';

/// Products in the home "Gợi Ý Dành Cho Bạn" grid.
const int _personalizedLimit = 8;

class HomeState {
  const HomeState({
    this.isLoading = false,
    this.errorMessage,
    this.banners = const [],
    this.categories = const [],
    this.bestSellers = const [],
    this.personalizedProducts = const [],
    this.personalizedSource,
    this.personalizedReason,
    this.products = const [],
    this.selectedCategoryId,
    this.search = '',
  });

  final bool isLoading;
  final String? errorMessage;
  final List<BannerItem> banners;
  final List<Category> categories;
  final List<Product> bestSellers;
  final List<Product> personalizedProducts;
  final String? personalizedSource;
  final String? personalizedReason;
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
    List<Product>? personalizedProducts,
    String? personalizedSource,
    String? personalizedReason,
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
      personalizedProducts: personalizedProducts ?? this.personalizedProducts,
      personalizedSource: personalizedSource ?? this.personalizedSource,
      personalizedReason: personalizedReason ?? this.personalizedReason,
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
        repo.getPersonalizedProducts(limit: _personalizedLimit),
      ]);

      final bestSellers = results[2] as List<Product>;
      final personalized = results[3] as PersonalizedProductsResult;
      state = state.copyWith(
        isLoading: false,
        banners: results[0] as List<BannerItem>,
        categories: results[1] as List<Category>,
        bestSellers: bestSellers,
        personalizedProducts: personalized.products,
        personalizedSource: personalized.source,
        personalizedReason: personalized.reason,
        products: bestSellers,
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
