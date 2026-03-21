import 'package:flutter/foundation.dart';

import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';
import 'package:bakery_mobile/src/features/catalog/data/repositories/catalog_repository.dart';

enum SearchSortOption { popular, newest, priceAsc, priceDesc }

class SearchViewModel extends ChangeNotifier {
  SearchViewModel(this._catalogRepository);

  final CatalogRepository _catalogRepository;
  static const _pageSize = 16;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _query = '';
  SearchSortOption _sort = SearchSortOption.popular;
  List<Product> _products = [];
  int _page = 1;
  int _total = 0;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String get query => _query;
  SearchSortOption get sort => _sort;
  List<Product> get products => _sorted(_products);
  bool get hasMore => _products.length < _total;

  Future<void> search(String raw) async {
    _query = raw.trim();
    if (_query.isEmpty) {
      _products = [];
      _total = 0;
      _page = 1;
      _error = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _page = 1;
      final result = await _catalogRepository.getProductsPage(
        search: _query,
        page: _page,
        limit: _pageSize,
      );
      _products = result.products;
      _total = result.total;
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
      _products = [];
      _total = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_query.isEmpty || _isLoading || _isLoadingMore || !hasMore) return;

    _isLoadingMore = true;
    notifyListeners();
    try {
      final nextPage = _page + 1;
      final result = await _catalogRepository.getProductsPage(
        search: _query,
        page: nextPage,
        limit: _pageSize,
      );
      _page = nextPage;
      _total = result.total;
      _products = [..._products, ...result.products];
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void setSort(SearchSortOption value) {
    _sort = value;
    notifyListeners();
  }

  List<Product> _sorted(List<Product> data) {
    final list = [...data];
    switch (_sort) {
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
}


