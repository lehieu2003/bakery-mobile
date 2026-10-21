import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_box_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_product_rail_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

/// Matches the product detail screen: room for its pinned bottom bar.
const double _bottomBarClearance = 120;

class SkeletonProductDetailWidget extends StatelessWidget {
  const SkeletonProductDetailWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasCream,
      body: ListView(
        padding: EdgeInsets.zero,
        children: const [
          SkeletonBoxWidget(
            width: double.infinity,
            height: 360,
            borderRadius: 0,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              _bottomBarClearance,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBoxWidget(width: double.infinity, height: 24),
                Gap(AppSpacing.md),
                SkeletonBoxWidget(width: 230, height: 24),
                Gap(AppSpacing.xl),
                Row(
                  children: [
                    SkeletonBoxWidget(width: 142, height: 24),
                    Spacer(),
                    SkeletonBoxWidget(width: 92, height: 30, borderRadius: 999),
                  ],
                ),
                Gap(AppSpacing.xxl),
                SkeletonBoxWidget(width: 130, height: 18),
                Gap(AppSpacing.md),
                SkeletonBoxWidget(width: double.infinity, height: 13),
                Gap(AppSpacing.sm),
                SkeletonBoxWidget(width: double.infinity, height: 13),
                Gap(AppSpacing.sm),
                SkeletonBoxWidget(width: 240, height: 13),
                Gap(AppSpacing.xxl),
                SkeletonBoxWidget(width: double.infinity, height: 118),
                Gap(AppSpacing.xxl),
                SkeletonBoxWidget(width: 170, height: 18),
                Gap(AppSpacing.md),
                SkeletonProductRailWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
