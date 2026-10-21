import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';

/// Typography presets for [SummaryRowWidget].
enum SummaryRowVariant {
  /// Both sides in body text (price breakdown lines).
  regular,

  /// Value in bold (checkout summary, product facts).
  emphasis,

  /// Whole line large and bold (order total).
  total,
}

/// Label on the left, value right-aligned — price breakdowns and totals.
class SummaryRowWidget extends StatelessWidget {
  const SummaryRowWidget({
    super.key,
    required this.label,
    required this.value,
    this.variant = SummaryRowVariant.regular,
    this.valueColor,
  });

  final String label;
  final String value;
  final SummaryRowVariant variant;

  /// Overrides the value color (e.g. green discounts, brand-colored total).
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (TextStyle? labelStyle, TextStyle? valueStyle) = switch (variant) {
      SummaryRowVariant.regular => (
        textTheme.bodyMedium,
        textTheme.bodyMedium?.copyWith(color: valueColor),
      ),
      SummaryRowVariant.emphasis => (
        textTheme.bodyMedium,
        textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: valueColor,
        ),
      ),
      SummaryRowVariant.total => (
        textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppTheme.inkBrown,
        ),
        textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: valueColor ?? AppTheme.inkBrown,
        ),
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // The label takes the remaining width so the value (an amount or a
          // short code, kept at its natural width) sits flush right.
          Expanded(child: Text(label, style: labelStyle)),
          const SizedBox(width: 10),
          Text(value, textAlign: TextAlign.end, style: valueStyle),
        ],
      ),
    );
  }
}
