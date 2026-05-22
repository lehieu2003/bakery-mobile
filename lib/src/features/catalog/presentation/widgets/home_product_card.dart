import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/core/utils/image_url.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/product_detail_screen.dart';

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

    _imageTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_imageController.hasClients) return;
      final next = (_activeIndex + 1) % images.length;
      _imageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 260),
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
        borderRadius: BorderRadius.circular(18),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                              if (imageUrl.isEmpty) {
                                return const ColoredBox(
                                  color: Color(0xFFD8D8D8),
                                );
                              }
                              return Image.network(
                                imageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const ColoredBox(color: Color(0xFFD8D8D8)),
                              );
                            },
                          ),
                        ),
                        if (discount != null)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE46F5B),
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.10),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                '-$discount%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        if (images.length > 1)
                          Positioned(
                            right: 8,
                            top: discount == null ? 8 : 40,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(999),
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
                            borderRadius: BorderRadius.circular(999),
                            child: InkWell(
                              onTap: isPendingFavorite
                                  ? null
                                  : () => wishlistNotifier.toggle(product),
                              borderRadius: BorderRadius.circular(999),
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: isPendingFavorite
                                    ? const Padding(
                                        padding: EdgeInsets.all(7),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        size: 18,
                                        color: isFavorite
                                            ? Colors.redAccent
                                            : const Color(0xFF555555),
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
                    padding: const EdgeInsets.fromLTRB(12, 10, 44, 12),
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
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                '${product.price.toStringAsFixed(0)} VND',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.warmBrown,
                                ),
                              ),
                            ),
                            if (product.hasDiscount) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  product.comparePrice!.toStringAsFixed(0),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.inkBrown.withValues(
                                      alpha: 0.46,
                                    ),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                            ],
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
                    topLeft: Radius.circular(14),
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
                      topLeft: Radius.circular(14),
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
