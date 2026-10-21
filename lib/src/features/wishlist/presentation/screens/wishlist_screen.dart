import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/utils/image_url.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_tile_widget.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/product_detail_screen.dart';
import 'package:bakery_mobile/src/shared/widgets/app_network_image_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/discount_badge_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/price_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/favorite_icon_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wishlistViewModelProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(wishlistViewModelProvider);
    final notifier = ref.read(wishlistViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text('Favorites (${vm.items.length})')),
      body: RefreshIndicator(
        onRefresh: notifier.load,
        child: ListView(
          children: [
            if (vm.isLoading && vm.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    SkeletonTileWidget(),
                    SkeletonTileWidget(),
                    SkeletonTileWidget(),
                    SkeletonTileWidget(),
                  ],
                ),
              ),
            if (vm.error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  vm.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (!vm.isLoading && vm.items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No favorite products yet.')),
              ),
            ...vm.items.map((item) {
              final product = item.product;
              if (product == null) {
                return const ListTile(
                  leading: Icon(Icons.error_outline),
                  title: Text('Unavailable product'),
                );
              }

              final imageUrl = resolveImageUrl(product.thumbnail);
              final discount = product.discountPercent;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: SizedBox(
                  width: 54,
                  height: 54,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AppNetworkImageWidget(
                        url: imageUrl,
                        width: 48,
                        height: 48,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                        backgroundColor: AppTheme.imagePlaceholder,
                        errorIcon: Icons.image_not_supported_outlined,
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
                title: Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: PriceWidget(
                  price: product.price,
                  comparePrice: product.hasDiscount
                      ? product.comparePrice
                      : null,
                ),
                trailing: IconButton(
                  onPressed: vm.isPending(product.id)
                      ? null
                      : () => notifier.toggle(product),
                  icon: FavoriteIconWidget(
                    isFavorite: true,
                    isPending: vm.isPending(product.id),
                  ),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(
                      productIdOrSlug: product.slug.isNotEmpty
                          ? product.slug
                          : product.id,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
