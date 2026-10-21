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
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

class SearchProductTile extends ConsumerWidget {
  const SearchProductTile({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartViewModelProvider.notifier);
    final imageUrl = resolveImageUrl(product.thumbnail);
    final discount = product.discountPercent;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        leading: SizedBox(
          width: 58,
          height: 58,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AppNetworkImageWidget(
                url: imageUrl,
                width: 52,
                height: 52,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                backgroundColor: Colors.transparent,
                emptyIcon: null,
                errorIcon: null,
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
        title: Text(product.name),
        subtitle: PriceWidget(
          price: product.price,
          comparePrice: product.hasDiscount ? product.comparePrice : null,
        ),
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
