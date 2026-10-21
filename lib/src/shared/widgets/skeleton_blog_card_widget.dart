import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/shared/widgets/skeleton_box_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

class SkeletonBlogCardWidget extends StatelessWidget {
  const SkeletonBlogCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: LayoutBuilder(builder: skeletonFillBuilder),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBoxWidget(width: double.infinity, height: 18),
                Gap(AppSpacing.sm),
                SkeletonBoxWidget(width: 220, height: 18),
                Gap(AppSpacing.lg),
                SkeletonBoxWidget(width: double.infinity, height: 13),
                Gap(AppSpacing.sm),
                SkeletonBoxWidget(width: double.infinity, height: 13),
                Gap(AppSpacing.sm),
                SkeletonBoxWidget(width: 180, height: 13),
                Gap(AppSpacing.xl),
                SkeletonBoxWidget(width: 160, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
