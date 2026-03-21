import 'package:flutter/foundation.dart';

import 'package:bakery_mobile/src/features/catalog/domain/models/banner_item.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/category.dart'
    as bakery_models;
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';
import 'package:bakery_mobile/src/features/catalog/data/repositories/catalog_repository.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._catalogRepository);

  final CatalogRepository _catalogRepository;

  bool _isLoading = false;
  String? _errorMessage;

  List<BannerItem> _banners = [];
  List<bakery_models.Category> _categories = [];
  List<Product> _bestSellers = [];
  List<Product> _products = [];

  String? _selectedCategoryId;
  String _search = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<BannerItem> get banners => _banners;
  List<bakery_models.Category> get categories => _categories;
  List<Product> get bestSellers => _bestSellers;
  List<Product> get products => _products;
  String? get selectedCategoryId => _selectedCategoryId;

  Future<void> loadInitial() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _catalogRepository.getBanners(),
        _catalogRepository.getCategories(),
        _catalogRepository.getBestSellers(),
        _catalogRepository.getProducts(),
      ]);

      _banners = results[0] as List<BannerItem>;
      _categories = results[1] as List<bakery_models.Category>;
      _bestSellers = results[2] as List<Product>;
      _products = results[3] as List<Product>;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String value) async {
    _search = value.trim();
    await _reloadProducts();
  }

  Future<void> selectCategory(String? categoryId) async {
    _selectedCategoryId = categoryId;
    await _reloadProducts();
  }

  Future<void> _reloadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _catalogRepository.getProducts(
        categoryId: _selectedCategoryId,
        search: _search,
      );
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}


