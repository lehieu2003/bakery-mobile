import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/category.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/catalog_keys.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/controllers/category_view_model.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/widgets/home_product_card.dart';
import 'package:bakery_mobile/src/shared/widgets/empty_state_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/loading_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_product_grid_widget.dart';

/// Same card proportions as the home product grids.
const double _cardAspectRatio = 0.72;

/// Distance from the end of the list at which the next page is requested.
const double _loadMoreThreshold = 180;

/// Height of the subcategory chip row.
const double _chipRowHeight = 40;

/// Products of one category — the mobile counterpart of bakery-web's
/// `/categories/[...slug]`: the whole category ("Tất cả", including every
/// subcategory) or one subcategory picked from the chips, paged on scroll.
class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key, required this.category});

  final Category category;

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  final _scrollController = ScrollController();

  CategoryViewModel get _vm =>
      ref.read(categoryViewModelProvider(widget.category.id).notifier);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() => _vm.load());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      _vm.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final state = ref.watch(categoryViewModelProvider(category.id));
    final theme = Theme.of(context);
    final showSkeleton = state.isLoading && state.products.isEmpty;
    final showFullError =
        state.error != null && state.products.isEmpty && !state.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: CustomScrollView(
        key: CategoryKeys.list,
        controller: _scrollController,
        slivers: [
          if ((category.description ?? '').trim().isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  category.description!.trim(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ),
          if (category.children.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              sliver: SliverToBoxAdapter(
                child: _SubcategoryChips(
                  root: category,
                  selectedId: state.selectedCategoryId,
                  onSelect: _vm.select,
                ),
              ),
            ),
          if (!showSkeleton && !showFullError)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  '${state.total} sản phẩm',
                  key: CategoryKeys.resultCount,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ),
          if (showSkeleton)
            const SliverToBoxAdapter(
              child: SkeletonProductGridWidget(key: CategoryKeys.loading),
            )
          else if (showFullError)
            SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorRetryWidget(
                key: CategoryKeys.error,
                message: state.error!,
                onRetry: _vm.load,
              ),
            )
          else if (state.products.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateWidget(
                key: CategoryKeys.empty,
                icon: Icons.bakery_dining_outlined,
                message: 'Danh mục này chưa có sản phẩm.',
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverGrid.builder(
                itemCount: state.products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.lg,
                  crossAxisSpacing: AppSpacing.lg,
                  childAspectRatio: _cardAspectRatio,
                ),
                itemBuilder: (context, index) {
                  final product = state.products[index];
                  return HomeProductCard(
                    key: CategoryKeys.product(product.id),
                    product: product,
                  );
                },
              ),
            ),
            if (state.isLoadingMore)
              const SliverToBoxAdapter(
                child: LoadingWidget(
                  key: CategoryKeys.loadingMore,
                  padding: EdgeInsets.only(bottom: AppSpacing.xxl),
                ),
              )
            else if (state.error != null)
              SliverToBoxAdapter(
                child: ErrorRetryWidget(
                  message: state.error!,
                  onRetry: _vm.loadMore,
                  compact: true,
                ),
              ),
            const SliverToBoxAdapter(child: Gap(AppSpacing.xxl)),
          ],
        ],
      ),
    );
  }
}

/// "Tất cả" (the root, i.e. the whole tree) followed by the direct
/// subcategories; deeper levels are included in their parent's results.
class _SubcategoryChips extends StatelessWidget {
  const _SubcategoryChips({
    required this.root,
    required this.selectedId,
    required this.onSelect,
  });

  final Category root;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final options = [
      (id: root.id, label: 'Tất cả'),
      for (final child in root.children) (id: child.id, label: child.name),
    ];
    return SizedBox(
      height: _chipRowHeight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
        itemBuilder: (context, index) {
          final option = options[index];
          return ChoiceChip(
            key: CategoryKeys.chip(option.id),
            label: Text(option.label),
            selected: option.id == selectedId,
            onSelected: (_) => onSelect(option.id),
          );
        },
      ),
    );
  }
}
