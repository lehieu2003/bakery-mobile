import 'package:bakery_mobile/src/features/catalog/presentation/controllers/search_view_model.dart';
import 'package:flutter/widgets.dart';

/// Widget keys of the home screen (used by tests and finders).
abstract final class HomeKeys {
  static const list = Key('home.list');
  static const loading = Key('home.loading');
  static const banners = Key('home.banners');
  static const categoryRail = Key('home.categoryRail');
  static const personalized = Key('home.personalized');
  static const personalizedMessage = Key('home.personalizedMessage');
  static const bestSellers = Key('home.bestSellers');
  static const empty = Key('home.empty');
  static const error = Key('home.error');
  static const errorBanner = Key('home.errorBanner');

  static Key bestSeller(String id) => Key('home.bestSeller.$id');
  static Key personalizedItem(String id) => Key('home.personalized.$id');
}

/// Widget keys of the category screen (used by tests and finders).
abstract final class CategoryKeys {
  static const list = Key('category.list');
  static const loading = Key('category.loading');
  static const empty = Key('category.empty');
  static const error = Key('category.error');
  static const resultCount = Key('category.resultCount');
  static const loadingMore = Key('category.loadingMore');

  static Key chip(String categoryId) => Key('category.chip.$categoryId');
  static Key product(String id) => Key('category.product.$id');
}

/// Widget keys of the search screen (used by tests and finders).
abstract final class SearchKeys {
  static const list = Key('search.list');
  static const input = Key('search.input');
  static const resultCount = Key('search.resultCount');
  static const filters = Key('search.filters');
  static const loading = Key('search.loading');
  static const empty = Key('search.empty');
  static const error = Key('search.error');
  static const loadingMore = Key('search.loadingMore');
  static const loadMore = Key('search.loadMore');

  static Key sort(SearchSortOption option) => Key('search.sort.${option.name}');
  static Key product(String id) => Key('search.product.$id');
}
