import 'package:bakery_mobile/src/features/catalog/data/dtos/catalog_dto.dart';
import 'package:bakery_mobile/src/features/wishlist/domain/models/wishlist_item.dart';

class WishlistItemDto {
  const WishlistItemDto({
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
  final ProductDto? product;

  factory WishlistItemDto.fromJson(Map<String, dynamic> json) {
    final productMap = json['product'];
    return WishlistItemDto(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      productId: (json['productId'] ?? '').toString(),
      createdAt:
          DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
      product: productMap is Map<String, dynamic>
          ? ProductDto.fromJson(productMap)
          : null,
    );
  }

  WishlistItem toDomain() => WishlistItem(
    id: id,
    userId: userId,
    productId: productId,
    createdAt: createdAt,
    product: product?.toDomain(),
  );
}
