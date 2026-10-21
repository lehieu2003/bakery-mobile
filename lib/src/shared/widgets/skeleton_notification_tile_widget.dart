import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/shared/widgets/skeleton_box_widget.dart';

class SkeletonNotificationTileWidget extends StatelessWidget {
  const SkeletonNotificationTileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SkeletonBoxWidget(width: 40, height: 40, borderRadius: 999),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBoxWidget(width: double.infinity, height: 14),
                SizedBox(height: 8),
                SkeletonBoxWidget(width: 220, height: 12),
              ],
            ),
          ),
          SizedBox(width: 12),
          SkeletonBoxWidget(width: 52, height: 28, borderRadius: 999),
        ],
      ),
    );
  }
}
