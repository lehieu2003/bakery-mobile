/// A user review for a product, as exposed by
/// `GET /api/products/{id}/reviews`.
class ProductReview {
  const ProductReview({
    required this.id,
    required this.userId,
    required this.productId,
    required this.rating,
    required this.createdAt,
    this.comment,
    this.userName,
  });

  final String id;
  final String userId;
  final String productId;

  /// 1-5 stars.
  final int rating;
  final String? comment;
  final DateTime createdAt;

  /// Display name of the author; null when the account was removed or the
  /// server omits the relation.
  final String? userName;

  String get authorLabel {
    final name = userName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    return 'Người dùng ẩn danh';
  }
}

/// One page of reviews plus the total review count of the product.
class ReviewsPage {
  const ReviewsPage({required this.reviews, required this.reviewCount});

  final List<ProductReview> reviews;
  final int reviewCount;
}
