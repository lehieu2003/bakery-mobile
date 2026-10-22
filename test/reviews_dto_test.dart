import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/features/reviews/data/datasources/reviews_api_service.dart';
import 'package:bakery_mobile/src/features/reviews/data/dtos/review_dto.dart';
import 'package:bakery_mobile/src/features/reviews/data/repositories/reviews_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixtures mirror the web payload produced by the reviews routes
/// (`bakery-web/app/api/products/[id]/reviews/route.ts`):
///
/// - `GET /api/products/{id}/reviews` → `{ success, data: { reviews: [...],
///   pagination: { page, limit, total } } }`. `ApiClient.get` unwraps `data`,
///   so the service feeds the remaining map into `ReviewsListDto.fromJson`.
/// - `POST /api/products/{id}/reviews` body `{ rating, comment }` →
///   `{ success, data: { review } }` (the server upserts the user's review).
Map<String, dynamic> get _fullReview => {
  'id': 'review-1',
  'userId': 'user-1',
  'productId': 'product-1',
  'rating': 5,
  'comment': 'Bánh ngon, giao hàng nhanh!',
  'createdAt': '2026-10-03T01:02:03.000Z',
  'user': {'id': 'user-1', 'name': 'Nguyễn Văn A'},
  'someFutureField': 42,
};

class _CapturingApiClient extends ApiClient {
  _CapturingApiClient()
    : super(baseUrl: 'http://localhost', tokenProvider: () async => null);

  Object? lastBody;
  String? lastPath;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    lastPath = path;
    return {
      'reviews': [_fullReview],
      'pagination': {'page': 1, 'limit': 10, 'total': 7},
    };
  }

  @override
  Future<dynamic> post(String path, {Object? body}) async {
    lastPath = path;
    lastBody = body;
    return {'review': Map<String, dynamic>.from(_fullReview)..['rating'] = 4};
  }
}

void main() {
  group('ReviewDto.fromJson', () {
    test('parses full server payload', () {
      final dto = ReviewDto.fromJson(_fullReview);
      final review = dto.toDomain();

      expect(review.id, 'review-1');
      expect(review.userId, 'user-1');
      expect(review.productId, 'product-1');
      expect(review.rating, 5);
      expect(review.comment, 'Bánh ngon, giao hàng nhanh!');
      expect(review.createdAt, DateTime.utc(2026, 10, 3, 1, 2, 3));
      expect(review.userName, 'Nguyễn Văn A');
    });

    test('survives missing/null defensive fields', () {
      final review = ReviewDto.fromJson({
        'id': 'review-2',
        'rating': 3,
        'comment': null,
        'createdAt': null,
        'user': null,
      }).toDomain();

      expect(review.userId, isEmpty);
      expect(review.productId, isEmpty);
      expect(review.comment, isNull);
      expect(
        review.createdAt,
        isNotNull,
        reason: 'missing createdAt falls back to now instead of crashing',
      );
      expect(review.userName, isNull);
    });

    test('clamps rating into the 1-5 range', () {
      expect(
        ReviewDto.fromJson({..._fullReview, 'rating': 9}).toDomain().rating,
        5,
      );
      expect(
        ReviewDto.fromJson({..._fullReview, 'rating': 0}).toDomain().rating,
        1,
      );
      expect(
        ReviewDto.fromJson({..._fullReview, 'rating': '4'}).toDomain().rating,
        4,
      );
      expect(
        ReviewDto.fromJson({..._fullReview, 'rating': null}).toDomain().rating,
        1,
      );
    });

    test('list parsing via fromJsonList skips malformed entries', () {
      final dtos = ReviewDto.fromJsonList([
        _fullReview,
        {'id': 'review-3', 'rating': 2},
        'garbage',
      ]);

      expect(dtos, hasLength(2));
      expect(dtos[0].id, 'review-1');
      expect(dtos[1].id, 'review-3');
    });
  });

  group('ReviewsListDto.fromJson', () {
    test('parses reviews with pagination.total as reviewCount', () {
      final result = ReviewsListDto.fromJson({
        'reviews': [_fullReview],
        'pagination': {'page': 1, 'limit': 10, 'total': 7},
      }).toDomain();

      expect(result.reviews, hasLength(1));
      expect(result.reviews.first.id, 'review-1');
      expect(result.reviewCount, 7);
    });

    test('falls back to top-level reviewCount when pagination is missing', () {
      final result = ReviewsListDto.fromJson({
        'reviews': [_fullReview, _fullReview],
        'reviewCount': 12,
      }).toDomain();

      expect(result.reviewCount, 12);
    });

    test('falls back to reviews.length when totals are missing', () {
      final result = ReviewsListDto.fromJson({
        'reviews': [_fullReview],
        'pagination': null,
      }).toDomain();

      expect(result.reviewCount, 1);
    });

    test('empty list yields empty state', () {
      final result = ReviewsListDto.fromJson({
        'reviews': null,
        'pagination': {'total': 0},
      }).toDomain();

      expect(result.reviews, isEmpty);
      expect(result.reviewCount, 0);
    });
  });

  group('ReviewsApiService payload', () {
    test('GET hits the product reviews endpoint and parses the page', () async {
      final client = _CapturingApiClient();
      final repository = ReviewsRepository(ReviewsApiService(client));

      final page = await repository.getReviews('product-1');

      expect(client.lastPath, '/api/products/product-1/reviews');
      expect(page.reviews, hasLength(1));
      expect(page.reviews.first.id, 'review-1');
      expect(page.reviewCount, 7);
    });

    test(
      'POST sends {rating, comment} to the product reviews endpoint',
      () async {
        final client = _CapturingApiClient();
        final repository = ReviewsRepository(ReviewsApiService(client));

        final review = await repository.submitReview(
          'product-1',
          rating: 4,
          comment: 'Rất tốt',
        );

        expect(client.lastPath, '/api/products/product-1/reviews');
        expect(client.lastBody, {'rating': 4, 'comment': 'Rất tốt'});
        expect(review.rating, 4);
      },
    );

    test('POST omits comment when null', () async {
      final client = _CapturingApiClient();
      final repository = ReviewsRepository(ReviewsApiService(client));

      await repository.submitReview('product-1', rating: 5);

      expect(client.lastBody, {'rating': 5});
    });
  });
}
