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
    final product = widget.product;
    final images = _productImages(product);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                        child: PageView.builder(
                          controller: _imageController,
                          itemCount: images.length,
                          onPageChanged: (index) =>
                              setState(() => _activeIndex = index),
                          itemBuilder: (context, index) {
                            final imageUrl = images[index];
                            if (imageUrl.isEmpty) {
                              return const ColoredBox(color: Color(0xFFD8D8D8));
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
                      if (images.length > 1)
                        Positioned(
                          right: 6,
                          top: 6,
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
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(12, 10, 44, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.product.price.toStringAsFixed(0)} VND',
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
                    width: 42,
                    height: 42,
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
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
