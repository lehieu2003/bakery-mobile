import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/features/admin/content/blog/domain/models/blog_models.dart';
import 'package:bakery_mobile/src/features/admin/content/blog/presentation/controllers/blog_posts_admin_view_model.dart';
import 'package:bakery_mobile/src/features/admin/content/blog/presentation/widgets/blog_post_create_sheet.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';

/// Blog posts admin: paged list, DRAFT create sheet, publish toggle and
/// delete confirm.
class BlogPostsScreen extends ConsumerStatefulWidget {
  const BlogPostsScreen({super.key});

  @override
  ConsumerState<BlogPostsScreen> createState() => _BlogPostsScreenState();
}

class _BlogPostsScreenState extends ConsumerState<BlogPostsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(blogPostsAdminViewModelProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(blogPostsAdminViewModelProvider);
    final vm = ref.read(blogPostsAdminViewModelProvider.notifier);

    return Scaffold(
      body: state.isLoading && state.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.items.isEmpty
          ? ErrorRetryWidget(message: state.error!, onRetry: vm.load)
          : state.items.isEmpty
          ? Center(
              child: Text(
                'Chưa có bài viết nào',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : RefreshIndicator(
              onRefresh: vm.load,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: state.items.length,
                separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                itemBuilder: (context, index) =>
                    _PostCard(post: state.items[index]),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showBlogPostCreateSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm bài viết'),
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post});

  final BlogPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(blogPostsAdminViewModelProvider.notifier);
    final isPublished = post.status == 'PUBLISHED';

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('/${post.slug}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              blogStatusLabel(post.status),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isPublished ? Colors.green.shade700 : Colors.grey,
              ),
            ),
            const Gap(4),
            IconButton(
              tooltip: isPublished ? 'Hủy đăng' : 'Đăng bài',
              icon: Icon(
                isPublished ? Icons.unpublished : Icons.publish,
                size: 20,
              ),
              onPressed: () =>
                  vm.setStatus(post.id, isPublished ? 'DRAFT' : 'PUBLISHED'),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Xoá bài viết?'),
                    content: Text('"${post.title}" sẽ bị xoá vĩnh viễn.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Huỷ'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Xoá'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) await vm.remove(post.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
