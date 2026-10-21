import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/shared/widgets/skeleton_box_widget.dart';

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
            padding: EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBoxWidget(width: double.infinity, height: 18),
                SizedBox(height: 8),
                SkeletonBoxWidget(width: 220, height: 18),
                SizedBox(height: 14),
                SkeletonBoxWidget(width: double.infinity, height: 13),
                SizedBox(height: 8),
                SkeletonBoxWidget(width: double.infinity, height: 13),
                SizedBox(height: 8),
                SkeletonBoxWidget(width: 180, height: 13),
                SizedBox(height: 18),
                SkeletonBoxWidget(width: 160, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
