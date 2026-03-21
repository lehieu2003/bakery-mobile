import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productIdOrSlug});

  final String productIdOrSlug;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Product? _product;
  bool _isLoading = true;
  String? _error;
  ProductVariant? _selectedVariant;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(catalogRepositoryProvider);
      final product = await repo.getProductDetail(widget.productIdOrSlug);
      setState(() {
        _product = product;
        _selectedVariant = product.variants.isNotEmpty
            ? product.variants.first
            : null;
      });
    } catch (error) {
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.read(cartViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Product details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _product == null
          ? const Center(child: Text('Product not found'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: (_product!.thumbnail.isNotEmpty)
                      ? Image.network(
                          _product!.thumbnail,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const ColoredBox(color: Color(0xFFE9D7C3)),
                        )
                      : const ColoredBox(color: Color(0xFFE9D7C3)),
                ),
                const SizedBox(height: 16),
                Text(
                  _product!.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(_product!.description ?? _product!.shortDescription ?? ''),
                const SizedBox(height: 12),
                if (_product!.variants.isNotEmpty) ...[
                  const Text(
                    'Variant',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _product!.variants
                        .map(
                          (variant) => ChoiceChip(
                            label: Text(
                              '${variant.name} - ${variant.price.toStringAsFixed(0)} VND',
                            ),
                            selected: _selectedVariant?.id == variant.id,
                            onSelected: (_) =>
                                setState(() => _selectedVariant = variant),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton.icon(
                  onPressed: _product!.stock > 0
                      ? () {
                          cart.addProduct(_product!, variant: _selectedVariant);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Added to cart')),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text(
                    'Add to cart - ${(_selectedVariant?.price ?? _product!.price).toStringAsFixed(0)} VND',
                  ),
                ),
              ],
            ),
    );
  }
}
