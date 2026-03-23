import 'package:bakery_mobile/src/features/wishlist/data/datasources/wishlist_api_service.dart';
import 'package:bakery_mobile/src/features/wishlist/domain/models/wishlist_item.dart';

class WishlistRepository {
  WishlistRepository(this._wishlistApiService);

  final WishlistApiService _wishlistApiService;

  Future<List<WishlistItem>> getWishlist() async {
    final items = await _wishlistApiService.getWishlist();
    return items.map((item) => item.toDomain()).toList();
  }

  Future<WishlistItem> addToWishlist(String productId) async {
    final item = await _wishlistApiService.addToWishlist(productId);
    return item.toDomain();
  }

  Future<void> removeFromWishlist(String productId) async {
    await _wishlistApiService.removeFromWishlist(productId);
  }
}
