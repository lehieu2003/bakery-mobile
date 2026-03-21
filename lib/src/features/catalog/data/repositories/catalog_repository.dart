import 'package:bakery_mobile/src/features/catalog/domain/models/banner_item.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/category.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';
import 'package:bakery_mobile/src/features/catalog/data/datasources/catalog_api_service.dart';

class CatalogRepository {
  CatalogRepository(this._catalogApiService);

  final CatalogApiService _catalogApiService;

  Future<List<BannerItem>> getBanners() => _catalogApiService.getBanners();

  Future<List<Category>> getCategories() => _catalogApiService.getCategories();

  Future<List<Product>> getBestSellers() => _catalogApiService.getBestSellers();

  Future<List<Product>> getProducts({
    String? categoryId,
    String? search,
  }) async {
    final result = await _catalogApiService.getProducts(
      categoryId: categoryId,
      search: search,
    );
    return result.products;
  }

  Future<ProductListResult> getProductsPage({
    String? categoryId,
    String? search,
    int page = 1,
    int limit = 20,
  }) {
    return _catalogApiService.getProducts(
      categoryId: categoryId,
      search: search,
      page: page,
      limit: limit,
    );
  }

  Future<Product> getProductDetail(String idOrSlug) {
    return _catalogApiService.getProductDetail(idOrSlug);
  }
}


