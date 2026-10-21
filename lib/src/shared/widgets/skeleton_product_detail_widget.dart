import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_box_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_product_rail_widget.dart';

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
            padding: EdgeInsets.fromLTRB(16, 16, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBoxWidget(width: double.infinity, height: 24),
                SizedBox(height: 10),
                SkeletonBoxWidget(width: 230, height: 24),
                SizedBox(height: 18),
                Row(
                  children: [
                    SkeletonBoxWidget(width: 142, height: 24),
                    Spacer(),
                    SkeletonBoxWidget(width: 92, height: 30, borderRadius: 999),
                  ],
                ),
                SizedBox(height: 24),
                SkeletonBoxWidget(width: 130, height: 18),
                SizedBox(height: 12),
                SkeletonBoxWidget(width: double.infinity, height: 13),
                SizedBox(height: 8),
                SkeletonBoxWidget(width: double.infinity, height: 13),
                SizedBox(height: 8),
                SkeletonBoxWidget(width: 240, height: 13),
                SizedBox(height: 22),
                SkeletonBoxWidget(width: double.infinity, height: 118),
                SizedBox(height: 24),
                SkeletonBoxWidget(width: 170, height: 18),
                SizedBox(height: 12),
                SkeletonProductRailWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
