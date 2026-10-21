import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/shared/widgets/skeleton_box_widget.dart';

class SkeletonCategoryRailWidget extends StatelessWidget {
  const SkeletonCategoryRailWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return const SizedBox(
            width: 72,
            child: Column(
              children: [
                SkeletonBoxWidget(width: 54, height: 54, borderRadius: 999),
                SizedBox(height: 8),
                SkeletonBoxWidget(width: 62, height: 10, borderRadius: 999),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: 5,
      ),
    );
  }
}
