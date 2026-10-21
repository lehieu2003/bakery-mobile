import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/shared/widgets/skeleton_product_card_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

class SkeletonProductGridWidget extends StatelessWidget {
  const SkeletonProductGridWidget({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.lg,
          crossAxisSpacing: AppSpacing.lg,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (context, index) => const SkeletonProductCardWidget(),
      ),
    );
  }
}
