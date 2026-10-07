import 'package:bakery_mobile/src/features/reviews/data/datasources/reviews_api_service.dart';
import 'package:bakery_mobile/src/features/reviews/data/dtos/review_dto.dart';
import 'package:bakery_mobile/src/features/reviews/domain/models/product_review.dart';

class ReviewsRepository {
  ReviewsRepository(this._reviewsApiService);

  final ReviewsApiService _reviewsApiService;

  Future<ReviewsPage> getReviews(String productId) async {
    final payload = await _reviewsApiService.getReviews(productId);
    return ReviewsListDto.fromJson(payload).toDomain();
  }

  /// Submits the user's review; the list should be reloaded afterwards to
  /// pick up the new/updated entry and the fresh review count.
  Future<ProductReview> submitReview(
    String productId, {
    required int rating,
    String? comment,
  }) async {
    final review = await _reviewsApiService.submitReview(
      productId,
      rating: rating,
      comment: comment,
    );
    return ReviewDto.fromJson(review).toDomain();
  }
}
