import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/features/auth/presentation/screens/auth_screen.dart';
import 'package:bakery_mobile/src/features/reviews/domain/models/product_review.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

/// Mirrors MAX_COMMENT_LENGTH in bakery-web app/api/products/[id]/reviews.
const int _maxCommentLength = 2000;

/// Reviews section for the product detail screen: average-star header,
/// the review list, and a "Viết đánh giá" action (login prompt for guests,
/// a bottom-sheet form for signed-in users).
class ProductReviewsSection extends ConsumerWidget {
  const ProductReviewsSection({
    super.key,
    required this.productId,
    this.productRatingAverage,
    this.productReviewCount,
  });

  final String productId;

  /// Stats from the product detail payload; used until the review list
  /// provides fresher values.
  final double? productRatingAverage;
  final int? productReviewCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(reviewsViewModelProvider(productId));
    final isAuthenticated = ref.watch(
      authViewModelProvider.select((auth) => auth.isAuthenticated),
    );

    final reviewCount =
        vm.reviewCount ?? productReviewCount ?? vm.reviews.length;
    final hasReviews = reviewCount > 0 || vm.reviews.isNotEmpty;
    final average = productRatingAverage ?? vm.averageRating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Đánh giá sản phẩm',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Gap(AppSpacing.sm),
        Row(
          children: [
            _StarDisplay(rating: average == null ? 0 : average.round()),
            const Gap(AppSpacing.sm),
            Flexible(
              child: Text(
                hasReviews && average != null
                    ? '${average.toStringAsFixed(1)} ($reviewCount đánh giá)'
                    : '($reviewCount đánh giá)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () =>
                  _onWriteReviewPressed(context, ref, isAuthenticated),
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text('Viết đánh giá'),
            ),
          ],
        ),
        const Gap(AppSpacing.xs),
        if (vm.isLoading && vm.reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (vm.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              vm.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          )
        else if (vm.reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: Text('Chưa có đánh giá nào.')),
          )
        else
          ...vm.reviews.map((review) => _ReviewTile(review: review)),
      ],
    );
  }

  Future<void> _onWriteReviewPressed(
    BuildContext context,
    WidgetRef ref,
    bool isAuthenticated,
  ) async {
    // Guests are sent to the auth screen instead of getting an error toast.
    if (!isAuthenticated) {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AuthScreen()));
      return;
    }

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReviewFormSheet(productId: productId),
    );
    if (submitted == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cảm ơn bạn đã đánh giá sản phẩm!')),
      );
    }
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final ProductReview review;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.authorLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.xxs),
          _StarDisplay(rating: review.rating, size: 16),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const Gap(AppSpacing.xs),
            Text(
              review.comment!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }
}

class _StarDisplay extends StatelessWidget {
  const _StarDisplay({required this.rating, this.size = 18});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          size: size,
          color: Colors.amber,
        );
      }),
    );
  }
}

/// Bottom-sheet form: interactive star row + comment field + submit.
class _ReviewFormSheet extends ConsumerStatefulWidget {
  const _ReviewFormSheet({required this.productId});

  final String productId;

  @override
  ConsumerState<_ReviewFormSheet> createState() => _ReviewFormSheetState();
}

class _ReviewFormSheetState extends ConsumerState<_ReviewFormSheet> {
  int _rating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final submitted = await ref
        .read(reviewsViewModelProvider(widget.productId).notifier)
        .submit(rating: _rating, comment: _commentController.text.trim());
    if (!mounted) return;
    if (submitted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(reviewsViewModelProvider(widget.productId));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: bottomInset + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Đánh giá của bạn',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Gap(AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final value = index + 1;
              return IconButton(
                tooltip: '$value sao',
                onPressed: () => setState(() => _rating = value),
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  size: 34,
                  color: Colors.amber,
                ),
              );
            }),
          ),
          const Gap(AppSpacing.sm),
          TextField(
            controller: _commentController,
            maxLines: 4,
            maxLength: _maxCommentLength,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              hintText: 'Chia sẻ cảm nhận của bạn về sản phẩm...',
              border: OutlineInputBorder(),
            ),
          ),
          if (vm.submitError != null) ...[
            const Gap(AppSpacing.sm),
            Text(
              vm.submitError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const Gap(AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: vm.isSubmitting ? null : _submit,
              child: vm.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Gửi đánh giá'),
            ),
          ),
        ],
      ),
    );
  }
}
