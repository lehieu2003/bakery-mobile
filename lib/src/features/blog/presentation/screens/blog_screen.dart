import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/widgets/app_text_input.dart';
import 'package:bakery_mobile/src/features/blog/presentation/widgets/blog_post_card.dart';

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
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            AppTextInput(
              textInputAction: TextInputAction.search,
              hintText: 'Search blog posts...',
              prefixIcon: const Icon(Icons.search),
              onSubmitted: (text) => ref
                  .read(blogViewModelProvider.notifier)
                  .applyFilter(search: text),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('All categories'),
                      selected: vm.categorySlug.isEmpty,
                      onSelected: (_) => ref
                          .read(blogViewModelProvider.notifier)
                          .applyFilter(categorySlug: '', tagSlug: ''),
                    ),
                  ),
                  ...vm.categories.map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
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
            const SizedBox(height: 10),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...vm.tags.map(
                    (tag) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
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
            const SizedBox(height: 16),
            if (vm.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (vm.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  vm.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (!vm.isLoading && vm.posts.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: Text('No blog posts found.')),
              ),
            ...vm.posts.map(
              (post) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BlogPostCard(post: post),
              ),
            ),
            if (vm.isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!vm.isLoading && !vm.isLoadingMore && vm.hasMore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: OutlinedButton(
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
