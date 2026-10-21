import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

/// "Nothing here" state: muted [message], optionally with an [icon] above
/// it, centered in the available space.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.message,
    this.icon,
    this.padding = const EdgeInsets.all(AppSpacing.xxl),
  });

  final String message;
  final IconData? icon;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final glyph = icon;
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (glyph != null) ...[
              Icon(
                glyph,
                size: 44,
                color: AppTheme.warmBrown.withValues(alpha: 0.6),
              ),
              const Gap(AppSpacing.md),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.warmBrown),
            ),
          ],
        ),
      ),
    );
  }
}
