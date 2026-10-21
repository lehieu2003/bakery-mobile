import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/shared/widgets/skeleton_box_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_tile_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

class SkeletonBlogDetailWidget extends StatelessWidget {
  const SkeletonBlogDetailWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.x3l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBoxWidget(width: 92, height: 24, borderRadius: 999),
          Gap(AppSpacing.lg),
          SkeletonBoxWidget(width: double.infinity, height: 26),
          Gap(AppSpacing.md),
          SkeletonBoxWidget(width: 260, height: 26),
          Gap(AppSpacing.lg),
          SkeletonBoxWidget(width: double.infinity, height: 56),
          Gap(AppSpacing.lg),
          SkeletonBoxWidget(width: 220, height: 14),
          Gap(AppSpacing.xl),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: LayoutBuilder(builder: skeletonFillBuilder),
          ),
          Gap(AppSpacing.xl),
          SkeletonBoxWidget(width: double.infinity, height: 160),
          Gap(AppSpacing.xxl),
          SkeletonBoxWidget(width: 170, height: 18),
          Gap(AppSpacing.md),
          SkeletonTileWidget(),
          SkeletonTileWidget(),
        ],
      ),
    );
  }
}
