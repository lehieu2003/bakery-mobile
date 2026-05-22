import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/utils/image_url.dart';
import 'package:bakery_mobile/src/core/widgets/skeleton_widgets.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/product_detail_screen.dart';

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
                    SkeletonTile(),
                    SkeletonTile(),
                    SkeletonTile(),
                    SkeletonTile(),
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 48,
                                  height: 48,
                                  color: const Color(0xFFE0E0E0),
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                  ),
                                ),
                              )
                            : Container(
                                width: 48,
                                height: 48,
                                color: const Color(0xFFE0E0E0),
                                child: const Icon(Icons.image_outlined),
                              ),
                      ),
                      if (discount != null)
                        Positioned(
                          right: 0,
                          top: -3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE46F5B),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '-$discount%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                title: Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('${product.price.toStringAsFixed(0)} VND'),
                    if (product.hasDiscount)
                      Text(
                        '${product.comparePrice!.toStringAsFixed(0)} VND',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.44),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
                trailing: IconButton(
                  onPressed: vm.isPending(product.id)
                      ? null
                      : () => notifier.toggle(product),
                  icon: vm.isPending(product.id)
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.favorite, color: Colors.redAccent),
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
