import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

/// Card grouping one section of a detail screen: optional bold [title]
/// above [child], with the app's standard [AppSpacing.lg] padding.
class SectionCardWidget extends StatelessWidget {
  const SectionCardWidget({
    super.key,
    this.title,
    required this.child,
    this.margin,
  });

  final String? title;
  final Widget child;

  /// Defaults to the theme's card margin.
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final heading = title;
    return Card(
      margin: margin,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (heading != null) ...[
              Text(
                heading,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.inkBrown,
                ),
              ),
              const Gap(AppSpacing.sm),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
