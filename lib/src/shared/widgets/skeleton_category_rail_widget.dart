import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/shared/widgets/skeleton_box_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

class SkeletonCategoryRailWidget extends StatelessWidget {
  const SkeletonCategoryRailWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return const SizedBox(
            width: 72,
            child: Column(
              children: [
                SkeletonBoxWidget(width: 54, height: 54, borderRadius: 999),
                Gap(AppSpacing.sm),
                SkeletonBoxWidget(width: 62, height: 10, borderRadius: 999),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const Gap(AppSpacing.md),
        itemCount: 5,
      ),
    );
  }
}
