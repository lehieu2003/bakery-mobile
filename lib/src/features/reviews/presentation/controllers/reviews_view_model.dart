import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/reviews/domain/models/product_review.dart';

class ReviewsState {
  const ReviewsState({
    this.isLoading = false,
    this.error,
    this.reviews = const [],
    this.reviewCount,
    this.isSubmitting = false,
    this.submitError,
  });

  final bool isLoading;
  final String? error;
  final List<ProductReview> reviews;

  /// Total number of reviews for the product, from the server pagination
  /// (may exceed the number of loaded entries). Null until loaded.
  final int? reviewCount;
  final bool isSubmitting;
  final String? submitError;

  /// Average of the loaded reviews; only used when the product payload
  /// carries no `ratingAverage`.
  double? get averageRating {
    if (reviews.isEmpty) return null;
    final sum = reviews.fold<int>(0, (total, review) => total + review.rating);
    return sum / reviews.length;
  }

  ReviewsState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<ProductReview>? reviews,
    int? reviewCount,
    bool clearReviewCount = false,
    bool? isSubmitting,
    String? submitError,
    bool clearSubmitError = false,
  }) {
    return ReviewsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      reviews: reviews ?? this.reviews,
      reviewCount: clearReviewCount ? null : (reviewCount ?? this.reviewCount),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
    );
  }
}

/// Reviews of one product. Family-keyed by productId so every product
/// detail screen owns independent state: a second (stacked) PDP loads its
/// own reviews without overwriting or triggering reloads on the covered
/// one, and revisiting the first screen restores its list instantly.
class ReviewsViewModel extends FamilyNotifier<ReviewsState, String> {
  @override
  ReviewsState build(String arg) => const ReviewsState();

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearReviewCount: true,
    );
    try {
      final page = await ref.read(reviewsRepositoryProvider).getReviews(arg);
      state = state.copyWith(
        isLoading: false,
        reviews: page.reviews,
        reviewCount: page.reviewCount,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Submits the signed-in user's review and reloads the list on success.
  /// Returns true when the review went through.
  Future<bool> submit({required int rating, String? comment}) async {
    state = state.copyWith(isSubmitting: true, clearSubmitError: true);
    try {
      await ref
          .read(reviewsRepositoryProvider)
          .submitReview(arg, rating: rating, comment: comment);
      await _reload();
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: _submitErrorMessage(error),
      );
      return false;
    }
  }

  /// Refreshes the list after a successful submit without flashing the
  /// loading state.
  Future<void> _reload() async {
    try {
      final page = await ref.read(reviewsRepositoryProvider).getReviews(arg);
      state = state.copyWith(
        reviews: page.reviews,
        reviewCount: page.reviewCount,
      );
    } catch (_) {
      // The review was saved; keep the current list if the refresh fails.
    }
  }

  String _submitErrorMessage(Object error) {
    if (error is ApiException) {
      switch (error.statusCode) {
        case 401:
          return 'Vui lòng đăng nhập để đánh giá sản phẩm';
        case 409:
          return 'Bạn đã đánh giá sản phẩm này';
      }
    }
    return error.toString().replaceFirst('Exception: ', '');
  }
}
