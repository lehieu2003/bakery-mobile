import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/core/utils/image_url.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';

class HomeProductCard extends ConsumerWidget {
  const HomeProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartViewModelProvider.notifier);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: product.thumbnail.isNotEmpty
                    ? Image.network(
                        resolveImageUrl(product.thumbnail),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: Color(0xFFD8D8D8)),
                      )
                    : const ColoredBox(color: Color(0xFFD8D8D8)),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 10, 44, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.price.toStringAsFixed(0)} VND',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: AppTheme.primaryPink,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
              ),
              child: InkWell(
                onTap: product.stock <= 0
                    ? null
                    : () {
                        cart.addProduct(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to cart')),
                        );
                      },
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                ),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
