import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/utils/image_url.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/product_detail_screen.dart';
import 'package:bakery_mobile/src/shared/widgets/app_network_image_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/discount_badge_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/price_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';

class SuggestedProductTile extends ConsumerWidget {
  const SuggestedProductTile({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartViewModelProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final imageUrl = resolveImageUrl(product.thumbnail);
    final outOfStock = product.stock <= 0;
    final discount = product.discountPercent;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {
          final idOrSlug = product.slug.isNotEmpty ? product.slug : product.id;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(productIdOrSlug: idOrSlug),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 62,
                height: 60,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AppNetworkImageWidget(
                      url: imageUrl,
                      width: 56,
                      height: 56,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      backgroundColor: scheme.surfaceContainerHighest,
                      iconSize: 20,
                    ),
                    if (discount != null)
                      Positioned(
                        right: 0,
                        top: -3,
                        child: DiscountBadgeWidget(percent: discount),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Flexible(
                          child: PriceWidget(
                            price: product.price,
                            comparePrice: product.hasDiscount
                                ? product.comparePrice
                                : null,
                            variant: PriceVariant.chip,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (outOfStock)
                          Text(
                            'Hết hàng',
                            style: TextStyle(
                              color: scheme.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: const Size(0, 36),
                ),
                onPressed: outOfStock
                    ? null
                    : () {
                        cart.addProduct(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to cart')),
                        );
                      },
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
