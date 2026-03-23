import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/widgets/app_text_input.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/controllers/search_view_model.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/widgets/search_product_tile.dart';

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
    _debounce = Timer(const Duration(milliseconds: 350), () {
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
      appBar: AppBar(title: const Text('Search products')),
      body: ListView(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
        children: [
          AppTextInput(
            controller: _controller,
            textInputAction: TextInputAction.search,
            hintText: 'What are you looking for?',
            prefixIcon: const Icon(Icons.search),
            onSubmitted: (value) =>
                ref.read(searchViewModelProvider.notifier).search(value),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _sortChip(context, vm, SearchSortOption.popular, 'Popular'),
              _sortChip(context, vm, SearchSortOption.newest, 'Newest'),
              _sortChip(context, vm, SearchSortOption.priceAsc, 'Price asc'),
              _sortChip(context, vm, SearchSortOption.priceDesc, 'Price desc'),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              vm.query.isEmpty
                  ? 'All products (${vm.sortedProducts.length})'
                  : 'Found ${vm.sortedProducts.length} products for "${vm.query}"',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (vm.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!vm.isLoading && vm.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                vm.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (!vm.isLoading && vm.sortedProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Text(
                  vm.query.isEmpty
                      ? 'No products available.'
                      : 'No products found.',
                ),
              ),
            ),
          ...vm.sortedProducts.map(
            (product) => SearchProductTile(product: product),
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
                onPressed: ref.read(searchViewModelProvider.notifier).loadMore,
                child: const Text('Load more'),
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
      label: Text(label),
      selected: vm.sort == option,
      onSelected: (_) =>
          ref.read(searchViewModelProvider.notifier).setSort(option),
    );
  }
}
