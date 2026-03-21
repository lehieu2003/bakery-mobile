import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/banner_item.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/category.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';

class ProductListResult {
  const ProductListResult({required this.products, required this.total});

  final List<Product> products;
  final int total;
}

class CatalogApiService {
  CatalogApiService(this._client);

  final ApiClient _client;

  Future<List<BannerItem>> getBanners() async {
    final response = await _client.get('/api/public/banners');
    final raw = response as List<dynamic>? ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(BannerItem.fromJson)
        .where((banner) => banner.isActive)
        .toList();
  }

  Future<List<Category>> getCategories() async {
    final response = await _client.get('/api/public/categories');
    final categories =
        (response as Map<String, dynamic>)['categories'] as List<dynamic>? ??
        const [];
    return categories
        .whereType<Map<String, dynamic>>()
        .map(Category.fromJson)
        .toList();
  }

  Future<ProductListResult> getProducts({
    String? categoryId,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _client.get(
      '/api/public/products',
      query: {
        'page': page,
        'limit': limit,
        if (categoryId != null && categoryId.isNotEmpty)
          'categoryId': categoryId,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    final data = response as Map<String, dynamic>;
    final rawProducts = data['products'] as List<dynamic>? ?? const [];
    final pagination = data['pagination'] as Map<String, dynamic>? ?? const {};

    return ProductListResult(
      products: rawProducts
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList(),
      total: pagination['total'] is int
          ? pagination['total'] as int
          : int.tryParse('${pagination['total'] ?? ''}') ?? 0,
    );
  }

  Future<List<Product>> getBestSellers({int limit = 10}) async {
    final response = await _client.get(
      '/api/public/products/best-sellers',
      query: {'limit': limit},
    );

    final raw =
        (response as Map<String, dynamic>)['products'] as List<dynamic>? ??
        const [];

    return raw.whereType<Map<String, dynamic>>().map(Product.fromJson).toList();
  }

  Future<Product> getProductDetail(String idOrSlug) async {
    final response = await _client.get('/api/public/products/$idOrSlug');
    final data = response as Map<String, dynamic>;
    return Product.fromJson(data['product'] as Map<String, dynamic>? ?? {});
  }
}


