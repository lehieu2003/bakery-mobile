import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/shared/widgets/skeleton_box_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

class SkeletonBannerWidget extends StatelessWidget {
  const SkeletonBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: SkeletonBoxWidget(
        width: double.infinity,
        height: 190,
        borderRadius: 20,
      ),
    );
  }
}
