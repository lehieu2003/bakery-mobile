import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/shared/widgets/skeleton_box_widget.dart';

class SkeletonTileWidget extends StatelessWidget {
  const SkeletonTileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const SkeletonBoxWidget(width: 52, height: 52, borderRadius: 10),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBoxWidget(width: double.infinity, height: 14),
                  SizedBox(height: 10),
                  SkeletonBoxWidget(width: 120, height: 12),
                ],
              ),
            ),
            const SizedBox(width: 14),
            const SkeletonBoxWidget(width: 34, height: 34, borderRadius: 999),
          ],
        ),
      ),
    );
  }
}
