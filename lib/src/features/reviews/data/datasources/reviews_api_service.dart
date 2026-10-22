import 'package:bakery_mobile/src/core/network/api_client.dart';

/// Thin datasource over `/api/products/{id}/reviews`. Methods deal in raw
/// JSON maps so tests can substitute a fake [ApiClient] without knowing
/// about DTO parsing.
class ReviewsApiService {
  ReviewsApiService(this._client);

  final ApiClient _client;

  /// GET /api/products/{id}/reviews — public list, newest first, one page.
  Future<Map<String, dynamic>> getReviews(
    String productId, {
    int limit = 50,
  }) async {
    final response = await _client.get(
      '/api/products/${Uri.encodeComponent(productId)}/reviews',
      query: {'limit': limit},
    );
    return response as Map<String, dynamic>? ?? const {};
  }

  /// POST /api/products/{id}/reviews — creates (or, with the current server,
  /// upserts) the signed-in user's review. Requires auth (401 for guests);
  /// a duplicate may surface as 409 depending on the backend.
  Future<Map<String, dynamic>> submitReview(
    String productId, {
    required int rating,
    String? comment,
  }) async {
    final response = await _client.post(
      '/api/products/${Uri.encodeComponent(productId)}/reviews',
      body: {'rating': rating, if (comment != null) 'comment': comment},
    );
    final data = response as Map<String, dynamic>? ?? const {};
    final review = data['review'];
    return review is Map<String, dynamic> ? review : const {};
  }
}
