import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/shared/widgets/skeleton_box_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

class SkeletonTileWidget extends StatelessWidget {
  const SkeletonTileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            const SkeletonBoxWidget(width: 52, height: 52, borderRadius: 10),
            const Gap(AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBoxWidget(width: double.infinity, height: 14),
                  Gap(AppSpacing.md),
                  SkeletonBoxWidget(width: 120, height: 12),
                ],
              ),
            ),
            const Gap(AppSpacing.lg),
            const SkeletonBoxWidget(width: 34, height: 34, borderRadius: 999),
          ],
        ),
      ),
    );
  }
}
