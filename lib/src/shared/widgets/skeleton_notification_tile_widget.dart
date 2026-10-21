import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/shared/widgets/skeleton_box_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

class SkeletonNotificationTileWidget extends StatelessWidget {
  const SkeletonNotificationTileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          SkeletonBoxWidget(width: 40, height: 40, borderRadius: 999),
          Gap(AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBoxWidget(width: double.infinity, height: 14),
                Gap(AppSpacing.sm),
                SkeletonBoxWidget(width: 220, height: 12),
              ],
            ),
          ),
          Gap(AppSpacing.md),
          SkeletonBoxWidget(width: 52, height: 28, borderRadius: 999),
        ],
      ),
    );
  }
}
