import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';
import 'package:bakery_mobile/src/features/catalog/data/repositories/catalog_repository.dart';
import 'package:bakery_mobile/src/features/cart/presentation/controllers/cart_view_model.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/product_detail_screen.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/controllers/search_view_model.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          SearchViewModel(context.read<CatalogRepository>())
            ..search(initialQuery),
      child: _SearchView(initialQuery: initialQuery),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView({required this.initialQuery});

  final String initialQuery;

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  late final TextEditingController _controller;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _controller.addListener(_onQueryChanged);
    _scrollController.addListener(_onScroll);
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
      context.read<SearchViewModel>().search(_controller.text);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 180;
    if (_scrollController.position.pixels >= threshold) {
      context.read<SearchViewModel>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SearchViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Search products')),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'What are you looking for?',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (value) => vm.search(value),
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
          if (vm.query.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 30),
              child: Center(child: Text('Enter keyword to search products.')),
            ),
          if (vm.query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Found ${vm.products.length} products for "${vm.query}"',
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
          if (!vm.isLoading && vm.query.isNotEmpty && vm.products.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: Text('No products found.')),
            ),
          ...vm.products.map((product) => _SearchProductTile(product: product)),
          if (vm.isLoadingMore)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!vm.isLoading && !vm.isLoadingMore && vm.hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: OutlinedButton(
                onPressed: vm.loadMore,
                child: const Text('Load more'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sortChip(
    BuildContext context,
    SearchViewModel vm,
    SearchSortOption option,
    String label,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: vm.sort == option,
      onSelected: (_) => vm.setSort(option),
    );
  }
}

class _SearchProductTile extends StatelessWidget {
  const _SearchProductTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartViewModel>();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: product.thumbnail.isNotEmpty
            ? Image.network(
                product.thumbnail,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const SizedBox(width: 52, height: 52),
              )
            : const SizedBox(width: 52, height: 52),
        title: Text(product.name),
        subtitle: Text('${product.price.toStringAsFixed(0)} VND'),
        trailing: IconButton(
          icon: const Icon(Icons.add_shopping_cart),
          onPressed: product.stock <= 0
              ? null
              : () {
                  cart.addProduct(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Added to cart')),
                  );
                },
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(productIdOrSlug: product.slug),
          ),
        ),
      ),
    );
  }
}


