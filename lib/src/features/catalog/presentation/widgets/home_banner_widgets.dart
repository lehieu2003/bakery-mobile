import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/core/utils/image_url.dart';

class HomeHeroBanner extends StatelessWidget {
  const HomeHeroBanner({super.key, this.title, this.imageUrl});

  final String? title;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (resolveImageUrl(imageUrl).isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                resolveImageUrl(imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          if (resolveImageUrl(imageUrl).isNotEmpty)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.black.withValues(alpha: 0.16),
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
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HomeBannerDots extends StatelessWidget {
  const HomeBannerDots({
    super.key,
    required this.activeIndex,
    required this.count,
  });

  final int activeIndex;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == activeIndex;
        return Container(
          width: active ? 10 : 8,
          height: active ? 10 : 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppTheme.primaryPink : const Color(0xFFD0D0D0),
          ),
        );
      }),
    );
  }
}
