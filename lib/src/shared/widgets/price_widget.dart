import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/shared/utils/format_utils.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

/// Layout/typography presets for [PriceWidget].
enum PriceVariant {
  /// List tile subtitles (search, wishlist): wraps when narrow.
  compact,

  /// Product cards: single line, brown bold price, ellipsized.
  card,

  /// Price inside a tinted pill (chatbot suggestions), single line.
  chip,

  /// Product detail: large price, wraps when narrow.
  detail,
}

/// Selling [price] in VND, followed by the struck-through [comparePrice]
/// when it is higher (i.e. the product is discounted).
class PriceWidget extends StatelessWidget {
  const PriceWidget({
    super.key,
    required this.price,
    this.comparePrice,
    this.variant = PriceVariant.compact,
  });

  final num price;
  final num? comparePrice;
  final PriceVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final compare = comparePrice;
    final showCompare = compare != null && compare > price;

    switch (variant) {
      case PriceVariant.compact:
        return Wrap(
          spacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              formatVnd(price),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (showCompare)
              Text(
                formatVnd(compare),
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.44),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
          ],
        );
      case PriceVariant.detail:
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xxs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              formatVnd(price),
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppTheme.warmBrown,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (showCompare)
              Text(
                formatVnd(compare),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.inkBrown.withValues(alpha: 0.46),
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
          ],
        );
      case PriceVariant.card:
      case PriceVariant.chip:
        final isChip = variant == PriceVariant.chip;
        final priceText = Text(
          formatVnd(price),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: isChip
              ? TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                )
              : const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.warmBrown,
                ),
        );
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: isChip
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.end,
          children: [
            Flexible(
              child: isChip
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: priceText,
                    )
                  : priceText,
            ),
            if (showCompare) ...[
              const Gap(AppSpacing.sm),
              Flexible(
                child: Text(
                  formatVnd(compare),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isChip
                        ? scheme.onSurface.withValues(alpha: 0.42)
                        : AppTheme.inkBrown.withValues(alpha: 0.46),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
            ],
          ],
        );
    }
  }
}
