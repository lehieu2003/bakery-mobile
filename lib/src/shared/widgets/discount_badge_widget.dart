import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_radius.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

/// Size presets for [DiscountBadgeWidget].
enum DiscountBadgeVariant {
  /// List tiles and thumbnails (search, wishlist, chatbot suggestions).
  small,

  /// Product cards on image corners, with a soft shadow.
  medium,

  /// Product detail hero, with a stronger shadow.
  large,
}

/// Red "-NN%" pill shown on discounted products.
class DiscountBadgeWidget extends StatelessWidget {
  const DiscountBadgeWidget({
    super.key,
    required this.percent,
    this.variant = DiscountBadgeVariant.small,
  });

  final int percent;
  final DiscountBadgeVariant variant;

  static const Color color = Color(0xFFE46F5B);

  @override
  Widget build(BuildContext context) {
    final (padding, fontSize, shadow) = switch (variant) {
      DiscountBadgeVariant.small => (
        const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        9.0,
        null,
      ),
      DiscountBadgeVariant.medium => (
        const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        11.0,
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ),
      DiscountBadgeVariant.large => (
        const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        null,
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.14),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ),
    };
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: shadow == null ? null : [shadow],
      ),
      child: Text(
        '-$percent%',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
