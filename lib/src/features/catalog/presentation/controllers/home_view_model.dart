import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/features/catalog/data/repositories/catalog_repository.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/banner_item.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/category.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';
import 'package:bakery_mobile/src/shared/utils/error_message.dart';

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
  });

  final bool isLoading;
  final String? errorMessage;
  final List<BannerItem> banners;
  final List<Category> categories;
  final List<Product> bestSellers;
  final List<Product> personalizedProducts;
  final String? personalizedSource;
  final String? personalizedReason;

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
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: userErrorMessage(error),
      );
    }
  }
}
