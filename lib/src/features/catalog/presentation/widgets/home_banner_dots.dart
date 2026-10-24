import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

class HomeBannerDots extends StatelessWidget {
  const HomeBannerDots({
    super.key,
    required this.activeIndex,
    required this.count,
  });

  final int activeIndex;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == activeIndex;
        return Container(
          width: active ? 10 : 8,
          height: active ? 10 : 8,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppTheme.warmBrown : AppTheme.bannerDotInactive,
          ),
        );
      }),
    );
  }
}
