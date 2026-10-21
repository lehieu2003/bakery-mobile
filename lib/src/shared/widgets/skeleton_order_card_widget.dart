import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/shared/widgets/skeleton_box_widget.dart';

class SkeletonOrderCardWidget extends StatelessWidget {
  const SkeletonOrderCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: const [
            Row(
              children: [
                SkeletonBoxWidget(width: 40, height: 40, borderRadius: 999),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBoxWidget(width: 140, height: 14),
                      SizedBox(height: 8),
                      SkeletonBoxWidget(width: 210, height: 12),
                    ],
                  ),
                ),
                SizedBox(width: 10),
                SkeletonBoxWidget(width: 82, height: 18),
              ],
            ),
            SizedBox(height: 12),
            SkeletonBoxWidget(width: double.infinity, height: 38),
          ],
        ),
      ),
    );
  }
}
