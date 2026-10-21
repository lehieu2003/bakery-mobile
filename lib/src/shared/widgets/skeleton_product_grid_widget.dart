import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/shared/widgets/skeleton_product_card_widget.dart';

class SkeletonProductGridWidget extends StatelessWidget {
  const SkeletonProductGridWidget({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 14,
          childAspectRatio: 0.72,
        ),
        itemBuilder: (context, index) => const SkeletonProductCardWidget(),
      ),
    );
  }
}
