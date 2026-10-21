import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/shared/widgets/skeleton_box_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

class SkeletonOrderCardWidget extends StatelessWidget {
  const SkeletonOrderCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: const [
            Row(
              children: [
                SkeletonBoxWidget(width: 40, height: 40, borderRadius: 999),
                Gap(AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBoxWidget(width: 140, height: 14),
                      Gap(AppSpacing.sm),
                      SkeletonBoxWidget(width: 210, height: 12),
                    ],
                  ),
                ),
                Gap(AppSpacing.md),
                SkeletonBoxWidget(width: 82, height: 18),
              ],
            ),
            Gap(AppSpacing.md),
            SkeletonBoxWidget(width: double.infinity, height: 38),
          ],
        ),
      ),
    );
  }
}
