import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bakery_mobile/src/core/config/app_config.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/core/utils/image_url.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_blog_detail_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_box_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_tile_widget.dart';
import 'package:bakery_mobile/src/features/blog/domain/models/blog.dart';
import 'package:bakery_mobile/src/shared/widgets/app_network_image_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

/// Related posts displayed under an article.
const int _relatedPostsShown = 3;

/// Posts fetched for the "related" strip (the current post is filtered out
/// afterwards, so up to 3 remain).
const int _relatedPostsLimit = 4;

class BlogDetailScreen extends ConsumerStatefulWidget {
  const BlogDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends ConsumerState<BlogDetailScreen> {
  BlogPost? _post;
  List<BlogPost> _relatedPosts = const [];
  bool _isLoading = true;
  bool _isLoadingRelated = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(blogRepositoryProvider);
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final post = await repo.getPostBySlug(widget.slug);
      if (!mounted) return;
      setState(() => _post = post);
      _loadRelatedPosts(post);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRelatedPosts(BlogPost post) async {
    if (!mounted) return;
    setState(() => _isLoadingRelated = true);

    try {
      final result = await ref
          .read(blogRepositoryProvider)
          .getPosts(
            limit: _relatedPostsLimit,
            categorySlug: post.category?.slug,
          );
      if (!mounted) return;
      var posts = result.posts.where((item) => item.slug != post.slug).toList();

      if (posts.isEmpty) {
        final fallback = await ref
            .read(blogRepositoryProvider)
            .getPosts(limit: _relatedPostsLimit);
        posts = fallback.posts
            .where((item) => item.slug != post.slug)
            .take(_relatedPostsShown)
            .toList();
      }

      setState(() => _relatedPosts = posts.take(_relatedPostsShown).toList());
    } catch (_) {
      if (!mounted) return;
      setState(() => _relatedPosts = const []);
    } finally {
      if (mounted) setState(() => _isLoadingRelated = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;

    return Scaffold(
      backgroundColor: AppTheme.canvasCream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.canvasCream,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
            ),
            actions: [
              if (post != null)
                IconButton(
                  onPressed: () => _sharePost(post),
                  icon: const Icon(Icons.ios_share_rounded),
                  tooltip: 'Share',
                ),
            ],
          ),
          if (_isLoading)
            const SliverToBoxAdapter(child: SkeletonBlogDetailWidget())
          else if (_error != null || post == null)
            SliverFillRemaining(
              child: Center(child: Text(_error ?? 'Post not found')),
            )
          else
            SliverToBoxAdapter(
              child: _BlogPostContent(
                post: post,
                relatedPosts: _relatedPosts,
                isLoadingRelated: _isLoadingRelated,
                onShare: () => _sharePost(post),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _sharePost(BlogPost post) async {
    final url = _postUrl(post);
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Blog link copied'),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () {
            final uri = Uri.tryParse(url);
            if (uri != null) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),
      ),
    );
  }

  String _postUrl(BlogPost post) {
    final base = const AppConfig().baseUrl;
    final uri = Uri.tryParse(base);
    if (uri == null) return '/blog/${post.slug}';
    return uri.replace(path: '/blog/${post.slug}', query: null).toString();
  }
}

class _BlogPostContent extends StatelessWidget {
  const _BlogPostContent({
    required this.post,
    required this.relatedPosts,
    required this.isLoadingRelated,
    required this.onShare,
  });

  final BlogPost post;
  final List<BlogPost> relatedPosts;
  final bool isLoadingRelated;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveImageUrl(post.coverUrl);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.x3l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.category != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppTheme.blushPink.withValues(alpha: 0.26),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                post.category!.name.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.warmBrown,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          const Gap(AppSpacing.md),
          Text(
            post.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.inkBrown,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          if ((post.excerpt ?? '').trim().isNotEmpty) ...[
            const Gap(AppSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: AppTheme.blushPink.withValues(alpha: 0.75),
                    width: 4,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.md),
                child: Text(
                  post.excerpt!.trim(),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],
          const Gap(AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetaItem(
                icon: Icons.calendar_month_rounded,
                label: _formatDate(post.publishedAt),
              ),
              _MetaItem(
                icon: Icons.remove_red_eye_outlined,
                label: '${post.viewCount} lượt xem',
              ),
              InkWell(
                onTap: onShare,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                  child: _MetaItem(
                    icon: Icons.ios_share_rounded,
                    label: 'Chia sẻ',
                  ),
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.xl),
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: AppNetworkImageWidget(
                  url: imageUrl,
                  placeholder: const SizedBox.shrink(),
                ),
              ),
            ),
          if ((post.content ?? '').isNotEmpty) ...[
            const Gap(AppSpacing.xl),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.surfaceCream,
                borderRadius: BorderRadius.circular(AppRadius.xxl),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.warmBrown.withValues(alpha: 0.07),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Html(data: post.content ?? ''),
              ),
            ),
          ],
          if (post.tags.isNotEmpty) ...[
            const Gap(AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: post.tags
                  .map(
                    (tag) => Chip(
                      label: Text('#${tag.name}'),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
          const Gap(AppSpacing.xxl),
          if (isLoadingRelated)
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBoxWidget(width: 170, height: 18),
                Gap(AppSpacing.md),
                SkeletonTileWidget(),
                SkeletonTileWidget(),
              ],
            )
          else if (relatedPosts.isNotEmpty) ...[
            Text(
              'Bài viết liên quan',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.inkBrown,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Gap(AppSpacing.md),
            ...relatedPosts.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _RelatedBlogPostTile(post: item),
              ),
            ),
          ],
        ],
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

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const Gap(AppSpacing.xs),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RelatedBlogPostTile extends StatelessWidget {
  const _RelatedBlogPostTile({required this.post});

  final BlogPost post;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveImageUrl(post.coverUrl);

    return Material(
      color: AppTheme.surfaceCream,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => BlogDetailScreen(slug: post.slug)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(
                  width: 76,
                  height: 58,
                  child: AppNetworkImageWidget(
                    url: imageUrl,
                    backgroundColor: AppTheme.placeholderBeige,
                    emptyIcon: Icons.article_outlined,
                    errorIcon: Icons.article_outlined,
                    iconSize: 22,
                  ),
                ),
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.inkBrown,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const Gap(AppSpacing.xs),
                    Text(
                      _formatDate(post.publishedAt),
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
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
