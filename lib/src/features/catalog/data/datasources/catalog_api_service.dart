import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/features/catalog/data/dtos/catalog_dto.dart';

class CatalogApiService {
  CatalogApiService(this._client);

  final ApiClient _client;

  Future<List<BannerItemDto>> getBanners() async {
    final response = await _client.get('/api/public/banners');
    final raw = response as List<dynamic>? ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(BannerItemDto.fromJson)
        .where((banner) => banner.isActive)
        .toList();
  }

  Future<List<CategoryDto>> getCategories() async {
    final response = await _client.get('/api/public/categories');
    final categories =
        (response as Map<String, dynamic>)['categories'] as List<dynamic>? ??
        const [];
    return categories
        .whereType<Map<String, dynamic>>()
        .map(CategoryDto.fromJson)
        .toList();
  }

  Future<ProductListResultDto> getProducts({
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

    return ProductListResultDto(
      products: rawProducts
          .whereType<Map<String, dynamic>>()
          .map(ProductDto.fromJson)
          .toList(),
      total: pagination['total'] is int
          ? pagination['total'] as int
          : int.tryParse('${pagination['total'] ?? ''}') ?? 0,
    );
  }

  Future<List<ProductDto>> getBestSellers({int limit = 10}) async {
    final response = await _client.get(
      '/api/public/products/best-sellers',
      query: {'limit': limit},
    );

    final raw =
        (response as Map<String, dynamic>)['products'] as List<dynamic>? ??
        const [];

    return raw
        .whereType<Map<String, dynamic>>()
        .map(ProductDto.fromJson)
        .toList();
  }

  Future<PersonalizedProductsDto> getPersonalizedProducts({
    int limit = 12,
  }) async {
    final response = await _client.get(
      '/api/public/products/personalized',
      query: {'limit': limit},
    );

    return PersonalizedProductsDto.fromJson(response as Map<String, dynamic>);
  }

  Future<List<ProductDto>> getRelatedProducts(String idOrSlug) async {
    final response = await _client.get(
      '/api/public/products/$idOrSlug/related',
    );
    final raw = response as List<dynamic>? ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ProductDto.fromJson)
        .toList();
  }

  Future<ProductDto> getProductDetail(String idOrSlug) async {
    final response = await _client.get('/api/public/products/$idOrSlug');
    final data = response as Map<String, dynamic>;
    return ProductDto.fromJson(data['product'] as Map<String, dynamic>? ?? {});
  }
}
