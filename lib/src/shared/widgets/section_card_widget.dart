import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';

/// Card grouping one section of a detail screen: optional bold [title]
/// above [child], with the app's standard 14px padding.
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
        padding: const EdgeInsets.all(14),
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
              const SizedBox(height: 8),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
