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
import 'package:bakery_mobile/src/core/theme/app_radius.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/features/cart/presentation/widgets/added_to_cart_snack_bar.dart';

/// Material's minimum touch target.
const double _minTapSize = 48;

/// Favorite toggle on the card image: as large as the corner allows while
/// keeping the image visible (the heart itself stays small).
const double _favoriteTapSize = 44;

class HomeProductCard extends ConsumerStatefulWidget {
  const HomeProductCard({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<HomeProductCard> createState() => _HomeProductCardState();
}

class _HomeProductCardState extends ConsumerState<HomeProductCard> {
  late final PageController _imageController;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    // No autoplay: a grid of cards all cycling images at once is constant
    // motion with no way to stop it. The images stay swipeable.
    _imageController = PageController();
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.id == widget.product.id) return;
    _activeIndex = 0;
    if (_imageController.hasClients) {
      _imageController.jumpToPage(0);
    }
  }

  void _addToCart() {
    ref.read(cartViewModelProvider.notifier).addProduct(widget.product);
    showAddedToCartSnackBar(context, widget.product.name);
  }

  @override
  Widget build(BuildContext context) {
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
                                color: AppTheme.imageCounterScrim,
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
                          left: AppSpacing.xs,
                          top: AppSpacing.xs,
                          child: Semantics(
                            button: true,
                            toggled: isFavorite,
                            label: isFavorite
                                ? 'Bỏ ${product.name} khỏi yêu thích'
                                : 'Thêm ${product.name} vào yêu thích',
                            // Excluding the child drops the InkWell's tap
                            // action, so it is restated here.
                            onTap: isPendingFavorite
                                ? null
                                : () => wishlistNotifier.toggle(product),
                            excludeSemantics: true,
                            child: Material(
                              color: AppTheme.surfaceFavoriteButton,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              child: InkWell(
                                onTap: isPendingFavorite
                                    ? null
                                    : () => wishlistNotifier.toggle(product),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                                child: SizedBox(
                                  width: _favoriteTapSize,
                                  height: _favoriteTapSize,
                                  child: Center(
                                    child: FavoriteIconWidget(
                                      isFavorite: isFavorite,
                                      isPending: isPendingFavorite,
                                      size: 18,
                                      outlineColor: AppTheme.favoriteOutline,
                                    ),
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
                  child: Semantics(
                    button: true,
                    enabled: widget.product.stock > 0,
                    onTap: widget.product.stock <= 0 ? null : _addToCart,
                    label: widget.product.stock > 0
                        ? 'Thêm ${widget.product.name} vào giỏ'
                        : '${widget.product.name} đã hết hàng',
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: widget.product.stock <= 0 ? null : _addToCart,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppRadius.lg),
                      ),
                      child: const SizedBox(
                        width: _minTapSize,
                        height: _minTapSize,
                        child: Icon(Icons.add, color: Colors.white, size: 22),
                      ),
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
