import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/core/utils/image_url.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/product_detail_screen.dart';
import 'package:bakery_mobile/src/shared/widgets/app_network_image_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/discount_badge_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/price_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/favorite_icon_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_durations.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

/// Outlined heart over product photos.
const Color _favoriteOutline = Color(0xFF555555);

class HomeProductCard extends ConsumerStatefulWidget {
  const HomeProductCard({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<HomeProductCard> createState() => _HomeProductCardState();
}

class _HomeProductCardState extends ConsumerState<HomeProductCard> {
  late final PageController _imageController;
  Timer? _imageTimer;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _imageController = PageController();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    _imageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id == widget.product.id) return;
    _imageTimer?.cancel();
    _activeIndex = 0;
    if (_imageController.hasClients) {
      _imageController.jumpToPage(0);
    }
    _startAutoSlide();
  }

  void _startAutoSlide() {
    final images = _productImages(widget.product);
    if (images.length <= 1) return;

    _imageTimer = Timer.periodic(AppDurations.carouselAutoplay, (_) {
      if (!_imageController.hasClients) return;
      final next = (_activeIndex + 1) % images.length;
      _imageController.animateToPage(
        next,
        duration: AppDurations.medium,
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.read(cartViewModelProvider.notifier);
    final wishlist = ref.watch(wishlistViewModelProvider);
    final wishlistNotifier = ref.read(wishlistViewModelProvider.notifier);
    final product = widget.product;
    final images = _productImages(product);
    final isFavorite = wishlist.isFavorite(product.id);
    final isPendingFavorite = wishlist.isPending(product.id);
    final discount = product.discountPercent;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warmBrown.withValues(alpha: 0.09),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: AppTheme.surfaceCream,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
        ),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  ProductDetailScreen(productIdOrSlug: widget.product.slug),
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceCream,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.warmBrown.withValues(
                                    alpha: 0.10,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: PageView.builder(
                            controller: _imageController,
                            itemCount: images.length,
                            onPageChanged: (index) =>
                                setState(() => _activeIndex = index),
                            itemBuilder: (context, index) {
                              final imageUrl = images[index];
                              return AppNetworkImageWidget(
                                url: imageUrl,
                                width: double.infinity,
                                backgroundColor: AppTheme.imagePlaceholder,
                                emptyIcon: null,
                                errorIcon: null,
                              );
                            },
                          ),
                        ),
                        if (discount != null)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: DiscountBadgeWidget(
                              percent: discount,
                              variant: DiscountBadgeVariant.medium,
                            ),
                          ),
                        if (images.length > 1)
                          Positioned(
                            right: 8,
                            top: discount == null ? 8 : 40,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Text(
                                '${_activeIndex + 1}/${images.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          left: 8,
                          top: 8,
                          child: Material(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: InkWell(
                              onTap: isPendingFavorite
                                  ? null
                                  : () => wishlistNotifier.toggle(product),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: Center(
                                  child: FavoriteIconWidget(
                                    isFavorite: isFavorite,
                                    isPending: isPendingFavorite,
                                    size: 18,
                                    outlineColor: _favoriteOutline,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: AppTheme.surfaceCream,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.x5l,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                            color: AppTheme.inkBrown,
                          ),
                        ),
                        const Gap(AppSpacing.xs),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: PriceWidget(
                                price: product.price,
                                comparePrice: product.hasDiscount
                                    ? product.comparePrice
                                    : null,
                                variant: PriceVariant.card,
                              ),
                            ),
                          ],
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
                    topLeft: Radius.circular(AppRadius.lg),
                  ),
                  child: InkWell(
                    onTap: widget.product.stock <= 0
                        ? null
                        : () {
                            cart.addProduct(widget.product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to cart')),
                            );
                          },
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.lg),
                    ),
                    child: const SizedBox(
                      width: 38,
                      height: 38,
                      child: Icon(Icons.add, color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _productImages(Product product) {
    final urls = <String>[];

    final thumbnail = resolveImageUrl(product.thumbnail);
    if (thumbnail.isNotEmpty) {
      urls.add(thumbnail);
    }

    for (final image in product.images) {
      final url = resolveImageUrl(image.url);
      if (url.isEmpty || urls.contains(url)) continue;
      urls.add(url);
    }

    if (urls.isEmpty) {
      urls.add('');
    }
    return urls;
  }
}
