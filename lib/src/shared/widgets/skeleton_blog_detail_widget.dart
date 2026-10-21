import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/shared/widgets/skeleton_box_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_tile_widget.dart';

class SkeletonBlogDetailWidget extends StatelessWidget {
  const SkeletonBlogDetailWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBoxWidget(width: 92, height: 24, borderRadius: 999),
          SizedBox(height: 14),
          SkeletonBoxWidget(width: double.infinity, height: 26),
          SizedBox(height: 10),
          SkeletonBoxWidget(width: 260, height: 26),
          SizedBox(height: 16),
          SkeletonBoxWidget(width: double.infinity, height: 56),
          SizedBox(height: 16),
          SkeletonBoxWidget(width: 220, height: 14),
          SizedBox(height: 18),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: LayoutBuilder(builder: skeletonFillBuilder),
          ),
          SizedBox(height: 18),
          SkeletonBoxWidget(width: double.infinity, height: 160),
          SizedBox(height: 24),
          SkeletonBoxWidget(width: 170, height: 18),
          SizedBox(height: 12),
          SkeletonTileWidget(),
          SkeletonTileWidget(),
        ],
      ),
    );
  }
}
