import 'package:bakery_mobile/src/features/reviews/domain/models/product_review.dart';

/// DTO for a single review record returned by
/// `GET /api/products/{id}/reviews`:
/// `{ id, userId, productId, rating, comment, createdAt, user: { id, name } }`.
/// `user` and `comment` are nullable; parsing is defensive throughout.
class ReviewDto {
  const ReviewDto({
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
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final String? userName;

  factory ReviewDto.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userName = user is Map<String, dynamic>
        ? user['name']?.toString()
        : null;
    return ReviewDto(
      id: (json['id'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      productId: (json['productId'] ?? '').toString(),
      rating: _parseRating(json['rating']),
      comment: json['comment']?.toString(),
      createdAt:
          DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
      userName: (userName == null || userName.isEmpty) ? null : userName,
    );
  }

  static List<ReviewDto> fromJsonList(List<dynamic> raw) {
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ReviewDto.fromJson)
        .toList();
  }

  ProductReview toDomain() => ProductReview(
    id: id,
    userId: userId,
    productId: productId,
    rating: rating,
    comment: comment,
    createdAt: createdAt,
    userName: userName,
  );
}

/// The server validates 1-5, but old/odd payloads must not crash the UI.
int _parseRating(dynamic value) {
  int? parsed;
  if (value is num) {
    parsed = value.toInt();
  } else if (value is String) {
    parsed = int.tryParse(value);
  }
  if (parsed == null || parsed < 1) return 1;
  if (parsed > 5) return 5;
  return parsed;
}

/// DTO for the review list payload (after `ApiClient` unwraps `data`):
/// `{ reviews: [...], pagination: { page, limit, total } }`. Older shapes
/// with a top-level `reviewCount`/`total` are also accepted; the count
/// falls back to the number of parsed reviews.
class ReviewsListDto {
  const ReviewsListDto({required this.reviews, required this.reviewCount});

  final List<ReviewDto> reviews;
  final int reviewCount;

  factory ReviewsListDto.fromJson(Map<String, dynamic> json) {
    final rawReviews = json['reviews'] as List<dynamic>? ?? const [];
    final reviews = ReviewDto.fromJsonList(rawReviews);

    final pagination = json['pagination'];
    final total = pagination is Map<String, dynamic>
        ? _parseCount(pagination['total'])
        : null;
    final count =
        total ??
        _parseCount(json['reviewCount']) ??
        _parseCount(json['total']) ??
        reviews.length;

    return ReviewsListDto(reviews: reviews, reviewCount: count);
  }

  ReviewsPage toDomain() => ReviewsPage(
    reviews: reviews.map((review) => review.toDomain()).toList(),
    reviewCount: reviewCount,
  );
}

int? _parseCount(dynamic value) {
  if (value is num && value >= 0) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
