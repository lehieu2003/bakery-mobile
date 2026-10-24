import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/shared/widgets/app_text_input_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_tile_widget.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/controllers/search_view_model.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/widgets/search_product_tile.dart';
import 'package:bakery_mobile/src/shared/widgets/loading_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/empty_state_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/catalog_keys.dart';
import 'package:bakery_mobile/src/core/theme/app_durations.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SearchView(initialQuery: initialQuery);
  }
}

class _SearchView extends ConsumerStatefulWidget {
  const _SearchView({required this.initialQuery});

  final String initialQuery;

  @override
  ConsumerState<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<_SearchView> {
  late final TextEditingController _controller;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _controller.addListener(_onQueryChanged);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchViewModelProvider.notifier).loadFilters();
      ref.read(searchViewModelProvider.notifier).search(widget.initialQuery);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onQueryChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(AppDurations.searchDebounce, () {
      if (!mounted) return;
      ref.read(searchViewModelProvider.notifier).search(_controller.text);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 180;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(searchViewModelProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(searchViewModelProvider);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final keyboardVisible = keyboardInset > 0;
    final bottomInset = keyboardVisible
        ? keyboardInset + 16
        : MediaQuery.paddingOf(context).bottom + 110;

    return Scaffold(
      appBar: AppBar(title: const Text('Tìm sản phẩm')),
      body: ListView(
        key: SearchKeys.list,
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          bottomInset,
        ),
        children: [
          AppTextInputWidget(
            key: SearchKeys.input,
            controller: _controller,
            textInputAction: TextInputAction.search,
            hintText: 'Bạn đang tìm gì?',
            prefixIcon: const Icon(Icons.search),
            onSubmitted: (value) =>
                ref.read(searchViewModelProvider.notifier).search(value),
          ),
          const Gap(AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _sortChip(context, vm, SearchSortOption.popular, 'Phổ biến'),
              _sortChip(context, vm, SearchSortOption.newest, 'Mới nhất'),
              _sortChip(context, vm, SearchSortOption.priceAsc, 'Giá tăng dần'),
              _sortChip(
                context,
                vm,
                SearchSortOption.priceDesc,
                'Giá giảm dần',
              ),
              ActionChip(
                key: SearchKeys.filters,
                avatar: Icon(
                  vm.hasActiveFilters
                      ? Icons.filter_alt
                      : Icons.filter_alt_outlined,
                  size: 18,
                ),
                label: Text(vm.hasActiveFilters ? 'Đang lọc' : 'Bộ lọc'),
                onPressed: () => _openFilters(context, vm),
              ),
            ],
          ),
          const Gap(AppSpacing.lg),
          if (vm.error == null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                key: SearchKeys.resultCount,
                vm.query.isEmpty
                    ? 'Tất cả sản phẩm (${vm.sortedProducts.length})'
                    : 'Tìm thấy ${vm.sortedProducts.length} sản phẩm cho "${vm.query}"',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          if (vm.isLoading && vm.sortedProducts.isEmpty)
            const Column(
              key: SearchKeys.loading,
              children: [
                SkeletonTileWidget(),
                SkeletonTileWidget(),
                SkeletonTileWidget(),
                SkeletonTileWidget(),
                SkeletonTileWidget(),
                SkeletonTileWidget(),
              ],
            ),
          if (!vm.isLoading && vm.error != null && vm.sortedProducts.isEmpty)
            ErrorRetryWidget(
              key: SearchKeys.error,
              message: vm.error!,
              onRetry: () =>
                  ref.read(searchViewModelProvider.notifier).search(vm.query),
            ),
          if (!vm.isLoading && vm.error != null && vm.sortedProducts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                vm.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (!vm.isLoading && vm.error == null && vm.sortedProducts.isEmpty)
            EmptyStateWidget(
              key: SearchKeys.empty,
              message: vm.query.isEmpty
                  ? 'Chưa có sản phẩm.'
                  : 'Không tìm thấy sản phẩm.',
            ),
          ...vm.sortedProducts.map(
            (product) => SearchProductTile(
              key: SearchKeys.product(product.id),
              product: product,
            ),
          ),
          if (vm.isLoadingMore)
            const Padding(
              key: SearchKeys.loadingMore,
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: LoadingWidget(),
            ),
          if (!vm.isLoading && !vm.isLoadingMore && vm.hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: OutlinedButton(
                key: SearchKeys.loadMore,
                onPressed: ref.read(searchViewModelProvider.notifier).loadMore,
                child: const Text('Xem thêm'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sortChip(
    BuildContext context,
    SearchState vm,
    SearchSortOption option,
    String label,
  ) {
    return ChoiceChip(
      key: SearchKeys.sort(option),
      label: Text(label),
      selected: vm.sort == option,
      onSelected: (_) =>
          ref.read(searchViewModelProvider.notifier).setSort(option),
    );
  }

  Future<void> _openFilters(BuildContext context, SearchState vm) async {
    final minCtrl = TextEditingController(
      text: vm.minPrice?.toStringAsFixed(0) ?? '',
    );
    final maxCtrl = TextEditingController(
      text: vm.maxPrice?.toStringAsFixed(0) ?? '',
    );
    var inStock = vm.inStock == true;
    final selected = <String, Set<String>>{
      for (final filter in vm.selectedAttributeFilters)
        filter.attributeSlug: filter.valueSlugs.toSet(),
    };

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              top: false,
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
                ),
                children: [
                  Text(
                    'Lọc sản phẩm',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextInputWidget(
                          controller: minCtrl,
                          keyboardType: TextInputType.number,
                          labelText: 'Giá tối thiểu',
                        ),
                      ),
                      const Gap(AppSpacing.md),
                      Expanded(
                        child: AppTextInputWidget(
                          controller: maxCtrl,
                          keyboardType: TextInputType.number,
                          labelText: 'Giá tối đa',
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Chỉ còn hàng'),
                    value: inStock,
                    onChanged: (value) => setModalState(() => inStock = value),
                  ),
                  for (final group in vm.filters.groups) ...[
                    const Gap(AppSpacing.md),
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: group.values.map((value) {
                        final values = selected[group.slug] ?? <String>{};
                        final isSelected = values.contains(value.slug);
                        return FilterChip(
                          label: Text('${value.label} (${value.productCount})'),
                          selected: isSelected,
                          onSelected: (checked) {
                            setModalState(() {
                              final next = {...values};
                              if (checked) {
                                next.add(value.slug);
                              } else {
                                next.remove(value.slug);
                              }
                              if (next.isEmpty) {
                                selected.remove(group.slug);
                              } else {
                                selected[group.slug] = next;
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const Gap(AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ref
                                .read(searchViewModelProvider.notifier)
                                .clearFilters();
                            Navigator.of(sheetContext).pop();
                          },
                          child: const Text('Xóa bộ lọc'),
                        ),
                      ),
                      const Gap(AppSpacing.md),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final filters = selected.entries
                                .map(
                                  (entry) => ProductAttributeFilter(
                                    attributeSlug: entry.key,
                                    valueSlugs: entry.value.toList(),
                                  ),
                                )
                                .toList();
                            ref
                                .read(searchViewModelProvider.notifier)
                                .applyFilters(
                                  attributeFilters: filters,
                                  minPrice: double.tryParse(minCtrl.text),
                                  maxPrice: double.tryParse(maxCtrl.text),
                                  inStock: inStock ? true : null,
                                );
                            Navigator.of(sheetContext).pop();
                          },
                          child: const Text('Áp dụng'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    minCtrl.dispose();
    maxCtrl.dispose();
  }
}
