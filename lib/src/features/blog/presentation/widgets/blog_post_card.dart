import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/utils/image_url.dart';
import 'package:bakery_mobile/src/features/blog/domain/models/blog.dart';
import 'package:bakery_mobile/src/features/blog/presentation/screens/blog_detail_screen.dart';
import 'package:bakery_mobile/src/shared/widgets/app_network_image_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

class BlogPostCard extends StatelessWidget {
  const BlogPostCard({super.key, required this.post});

  final BlogPost post;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveImageUrl(post.coverUrl);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BlogDetailScreen(slug: post.slug)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: AppNetworkImageWidget(url: imageUrl, iconSize: 30),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.28,
                    ),
                  ),
                  if ((post.excerpt ?? '').trim().isNotEmpty) ...[
                    const Gap(AppSpacing.md),
                    Text(
                      post.excerpt!.trim(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 16,
                        height: 1.45,
                      ),
                    ),
                  ],
                  const Gap(AppSpacing.md),
                  Divider(
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                    height: 1,
                  ),
                  const Gap(AppSpacing.md),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                      const Gap(AppSpacing.xs),
                      Text(
                        _formatDate(post.publishedAt),
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(AppSpacing.md),
                      Icon(
                        Icons.remove_red_eye_outlined,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                      const Gap(AppSpacing.xs),
                      Text(
                        '${post.viewCount}',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Đọc',
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Gap(AppSpacing.xs),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: scheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '--/--/----';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day/$month/$year';
  }
}
