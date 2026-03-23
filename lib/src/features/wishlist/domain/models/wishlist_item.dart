import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';

class WishlistItem {
  const WishlistItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.createdAt,
    this.product,
  });

  final String id;
  final String userId;
  final String productId;
  final DateTime createdAt;
  final Product? product;
}
