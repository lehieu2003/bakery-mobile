import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/features/wishlist/data/dtos/wishlist_dto.dart';

class WishlistApiService {
  WishlistApiService(this._client);

  final ApiClient _client;

  Future<List<WishlistItemDto>> getWishlist() async {
    final response = await _client.get('/api/wishlist');
    final data = response as Map<String, dynamic>;
    final raw = data['wishlist'] as List<dynamic>? ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(WishlistItemDto.fromJson)
        .toList();
  }

  Future<WishlistItemDto> addToWishlist(String productId) async {
    final response = await _client.post(
      '/api/wishlist',
      body: {'productId': productId},
    );
    final data = response as Map<String, dynamic>;
    final item = data['item'] as Map<String, dynamic>? ?? const {};
    return WishlistItemDto.fromJson(item);
  }

  Future<void> removeFromWishlist(String productId) async {
    await _client.delete('/api/wishlist', body: {'productId': productId});
  }
}
