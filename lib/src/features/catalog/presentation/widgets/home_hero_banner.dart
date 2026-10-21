import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/core/utils/image_url.dart';
import 'package:bakery_mobile/src/shared/widgets/app_network_image_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';

class HomeHeroBanner extends StatelessWidget {
  const HomeHeroBanner({super.key, this.title, this.imageUrl});

  final String? title;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warmBrown.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (resolveImageUrl(imageUrl).isNotEmpty)
            AppNetworkImageWidget(
              url: imageUrl,
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              placeholder: const SizedBox.shrink(),
            ),
          if (resolveImageUrl(imageUrl).isNotEmpty)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.02),
                    Colors.black.withValues(alpha: 0.24),
                  ],
                ),
              ),
            ),
          if (title != null && title!.isNotEmpty)
            Positioned(
              left: 18,
              bottom: 18,
              right: 18,
              child: Text(
                title!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
