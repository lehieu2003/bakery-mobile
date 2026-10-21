import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/shared/widgets/skeleton_product_card_widget.dart';

class SkeletonProductRailWidget extends StatelessWidget {
  const SkeletonProductRailWidget({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 252,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return const SizedBox(width: 166, child: SkeletonProductCardWidget());
        },
      ),
    );
  }
}
