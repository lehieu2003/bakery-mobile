import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/shared/widgets/app_text_input_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_blog_card_widget.dart';
import 'package:bakery_mobile/src/features/blog/presentation/widgets/blog_post_card.dart';
import 'package:bakery_mobile/src/shared/widgets/loading_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/empty_state_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';
import 'package:bakery_mobile/src/features/blog/presentation/blog_keys.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

class BlogScreen extends ConsumerWidget {
  const BlogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _BlogView();
  }
}

class _BlogView extends ConsumerStatefulWidget {
  const _BlogView();

  @override
  ConsumerState<_BlogView> createState() => _BlogViewState();
}

class _BlogViewState extends ConsumerState<_BlogView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(blogViewModelProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 180;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(blogViewModelProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(blogViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Blog')),
      body: RefreshIndicator(
        onRefresh: ref.read(blogViewModelProvider.notifier).loadInitial,
        child: ListView(
          key: BlogKeys.list,
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppTextInputWidget(
              key: BlogKeys.search,
              textInputAction: TextInputAction.search,
              hintText: 'Search blog posts...',
              prefixIcon: const Icon(Icons.search),
              onSubmitted: (text) => ref
                  .read(blogViewModelProvider.notifier)
                  .applyFilter(search: text),
            ),
            const Gap(AppSpacing.md),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      key: BlogKeys.allCategories,
                      label: const Text('All categories'),
                      selected: vm.categorySlug.isEmpty,
                      onSelected: (_) => ref
                          .read(blogViewModelProvider.notifier)
                          .applyFilter(categorySlug: '', tagSlug: ''),
                    ),
                  ),
                  ...vm.categories.map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        key: BlogKeys.category(category.slug),
                        label: Text(category.name),
                        selected: vm.categorySlug == category.slug,
                        onSelected: (_) => ref
                            .read(blogViewModelProvider.notifier)
                            .applyFilter(
                              categorySlug: category.slug,
                              tagSlug: '',
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.md),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...vm.tags.map(
                    (tag) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: FilterChip(
                        key: BlogKeys.tag(tag.slug),
                        label: Text('#${tag.name}'),
                        selected: vm.tagSlug == tag.slug,
                        onSelected: (_) => ref
                            .read(blogViewModelProvider.notifier)
                            .applyFilter(
                              tagSlug: vm.tagSlug == tag.slug ? '' : tag.slug,
                              categorySlug: '',
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(AppSpacing.lg),
            if (vm.isLoading && vm.posts.isEmpty)
              const Column(
                key: BlogKeys.loading,
                spacing: AppSpacing.md,
                children: [
                  SkeletonBlogCardWidget(),
                  SkeletonBlogCardWidget(),
                  SkeletonBlogCardWidget(),
                ],
              ),
            if (vm.error != null && vm.posts.isEmpty && !vm.isLoading)
              ErrorRetryWidget(
                key: BlogKeys.error,
                message: vm.error!,
                onRetry: ref.read(blogViewModelProvider.notifier).loadInitial,
              ),
            if (vm.error != null && vm.posts.isNotEmpty)
              Padding(
                key: BlogKeys.errorBanner,
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  vm.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (!vm.isLoading && vm.error == null && vm.posts.isEmpty)
              const EmptyStateWidget(
                key: BlogKeys.empty,
                message: 'No blog posts found.',
              ),
            ...vm.posts.map(
              (post) => Padding(
                key: BlogKeys.post(post.id),
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: BlogPostCard(post: post),
              ),
            ),
            if (vm.isLoadingMore)
              const Padding(
                key: BlogKeys.loadingMore,
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: LoadingWidget(),
              ),
            if (!vm.isLoading && !vm.isLoadingMore && vm.hasMore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: OutlinedButton(
                  key: BlogKeys.loadMore,
                  onPressed: ref.read(blogViewModelProvider.notifier).loadMore,
                  child: const Text('Load more posts'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
