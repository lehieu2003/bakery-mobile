import 'package:bakery_mobile/src/features/catalog/domain/models/banner_item.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/category.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';
import 'package:bakery_mobile/src/features/catalog/data/datasources/catalog_api_service.dart';

class ProductListResult {
  const ProductListResult({required this.products, required this.total});

  final List<Product> products;
  final int total;
}

class PersonalizedProductsResult {
  const PersonalizedProductsResult({
    required this.products,
    required this.source,
    required this.reason,
  });

  final List<Product> products;
  final String source;
  final String reason;
}

class CatalogRepository {
  CatalogRepository(this._catalogApiService);

  final CatalogApiService _catalogApiService;

  Future<List<BannerItem>> getBanners() async {
    return (await _catalogApiService.getBanners())
        .map((e) => e.toDomain())
        .toList();
  }

  Future<List<Category>> getCategories() async {
    return (await _catalogApiService.getCategories())
        .map((e) => e.toDomain())
        .toList();
  }

  Future<List<Product>> getBestSellers() async {
    return (await _catalogApiService.getBestSellers())
        .map((e) => e.toDomain())
        .toList();
  }

  Future<PersonalizedProductsResult> getPersonalizedProducts({
    int limit = 12,
  }) async {
    final result = await _catalogApiService.getPersonalizedProducts(
      limit: limit,
    );
    return PersonalizedProductsResult(
      products: result.products.map((e) => e.toDomain()).toList(),
      source: result.source,
      reason: result.reason,
    );
  }

  Future<List<Product>> getRelatedProducts(String idOrSlug) async {
    return (await _catalogApiService.getRelatedProducts(
      idOrSlug,
    )).map((e) => e.toDomain()).toList();
  }

  Future<List<Product>> getProducts({
    String? categoryId,
    String? search,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    List<ProductAttributeFilter> attributeFilters = const [],
  }) async {
    final result = await _catalogApiService.getProducts(
      categoryId: categoryId,
      search: search,
      minPrice: minPrice,
      maxPrice: maxPrice,
      inStock: inStock,
      attributeFilters: _serializeAttributeFilters(attributeFilters),
    );
    return result.products.map((e) => e.toDomain()).toList();
  }

  Future<ProductListResult> getProductsPage({
    String? categoryId,
    String? search,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    List<ProductAttributeFilter> attributeFilters = const [],
    int page = 1,
    int limit = 20,
  }) async {
    final result = await _catalogApiService.getProducts(
      categoryId: categoryId,
      search: search,
      minPrice: minPrice,
      maxPrice: maxPrice,
      inStock: inStock,
      attributeFilters: _serializeAttributeFilters(attributeFilters),
      page: page,
      limit: limit,
    );
    return ProductListResult(
      products: result.products.map((e) => e.toDomain()).toList(),
      total: result.total,
    );
  }

  Future<Product> getProductDetail(String idOrSlug) async {
    return (await _catalogApiService.getProductDetail(idOrSlug)).toDomain();
  }

  Future<ProductFilters> getProductFilters({String? categoryId}) async {
    return (await _catalogApiService.getProductFilters(
      categoryId: categoryId,
    )).toDomain();
  }

  List<String> _serializeAttributeFilters(
    List<ProductAttributeFilter> filters,
  ) {
    return filters
        .where((filter) => filter.valueSlugs.isNotEmpty)
        .map(
          (filter) => '${filter.attributeSlug}:${filter.valueSlugs.join(',')}',
        )
        .toList();
  }
}
