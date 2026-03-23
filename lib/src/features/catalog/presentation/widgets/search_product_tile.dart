import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/utils/image_url.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/product_detail_screen.dart';

class SearchProductTile extends ConsumerWidget {
  const SearchProductTile({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartViewModelProvider.notifier);
    final imageUrl = resolveImageUrl(product.thumbnail);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
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
