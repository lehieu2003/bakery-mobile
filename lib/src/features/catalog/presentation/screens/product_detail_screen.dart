import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/core/utils/image_url.dart';
import 'package:bakery_mobile/src/core/widgets/skeleton_widgets.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/widgets/home_product_card.dart';
import 'package:bakery_mobile/src/features/reviews/presentation/widgets/product_reviews_section.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productIdOrSlug});

  final String productIdOrSlug;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final PageController _imageController = PageController(viewportFraction: 1);

  Product? _product;
  List<Product> _relatedProducts = const [];
  ProductVariant? _selectedVariant;
  bool _isLoading = true;
  bool _isLoadingRelated = false;
  String? _error;
  int _activeImageIndex = 0;
  Timer? _imageTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _imageTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final product = _product;
      if (product == null) return;
      final images = _productImages(product);
      if (!_imageController.hasClients || images.length <= 1) return;
      final next = (_activeImageIndex + 1) % images.length;
      _imageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(catalogRepositoryProvider);
      final product = await repo.getProductDetail(widget.productIdOrSlug);
      if (!mounted) return;
      setState(() {
        _product = product;
        _selectedVariant = product.variants.isNotEmpty
            ? product.variants.first
            : null;
        _activeImageIndex = 0;
      });
      unawaited(
        ref.read(reviewsViewModelProvider(product.id).notifier).load(),
      );
      unawaited(_loadRelatedProducts(product));
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadRelatedProducts(Product product) async {
    if (!mounted) return;
    setState(() => _isLoadingRelated = true);

    try {
      final products = await ref
          .read(catalogRepositoryProvider)
          .getRelatedProducts(
            product.slug.isNotEmpty ? product.slug : product.id,
          );
      if (!mounted) return;
      setState(() {
        _relatedProducts = products
            .where((item) => item.id != product.id)
            .take(8)
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _relatedProducts = const []);
    } finally {
      if (mounted) setState(() => _isLoadingRelated = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.read(cartViewModelProvider.notifier);
    final wishlist = ref.watch(wishlistViewModelProvider);
    final wishlistNotifier = ref.read(wishlistViewModelProvider.notifier);

    if (_isLoading) {
      return const SkeletonProductDetail();
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error!)),
      );
    }

    final product = _product;
    if (product == null) {
      return const Scaffold(body: Center(child: Text('Product not found')));
    }

    final currentPrice = _selectedVariant?.price ?? product.price;
    final originalPrice = product.comparePrice;
    final detailDiscount = originalPrice != null && originalPrice > currentPrice
        ? ((1 - currentPrice / originalPrice) * 100).round()
        : null;
    final images = _productImages(product);
    final hasVariants = product.variants.isNotEmpty;
    final summaryText = _displayDescription(product);
    final isFavorite = wishlist.isFavorite(product.id);
    final isPendingFavorite = wishlist.isPending(product.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 360,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              IconButton(
                onPressed: isPendingFavorite
                    ? null
                    : () => wishlistNotifier.toggle(product),
                icon: isPendingFavorite
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.redAccent : null,
                      ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _imageController,
                    itemCount: images.length,
                    onPageChanged: (index) =>
                        setState(() => _activeImageIndex = index),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => _openImageViewer(
                        context: context,
                        images: images,
                        initialIndex: index,
                      ),
                      child: Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFE9D7C3),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 88,
                    left: 16,
                    child: detailDiscount == null
                        ? const SizedBox.shrink()
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE46F5B),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Text(
                              '-$detailDiscount%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(images.length, (index) {
                        final active = _activeImageIndex == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: active ? 18 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '${currentPrice.toStringAsFixed(0)} VND',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: AppTheme.warmBrown,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            if (detailDiscount != null)
                              Text(
                                '${originalPrice!.toStringAsFixed(0)} VND',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.inkBrown.withValues(
                                        alpha: 0.46,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: product.stock > 0
                              ? Colors.green.withValues(alpha: 0.12)
                              : Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          product.stock > 0
                              ? 'Stock: ${product.stock}'
                              : 'Out of stock',
                          style: TextStyle(
                            color: product.stock > 0
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (summaryText.isNotEmpty) ...[
                    Text(
                      'Mô tả sản phẩm',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      summaryText,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (hasVariants) ...[
                    Text(
                      'Biến thể',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.variants
                          .map(
                            (variant) => ChoiceChip(
                              label: Text(
                                '${variant.name} - ${variant.price.toStringAsFixed(0)} VND',
                              ),
                              selected: _selectedVariant?.id == variant.id,
                              onSelected: (_) =>
                                  setState(() => _selectedVariant = variant),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                  ],
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        if (detailDiscount != null) ...[
                          _InfoRow(
                            label: 'Giá trước ưu đãi',
                            value: '${originalPrice!.toStringAsFixed(0)} VND',
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(label: 'Ưu đãi', value: '-$detailDiscount%'),
                          const SizedBox(height: 8),
                        ],
                        _InfoRow(
                          label: 'Giá đang chọn',
                          value: '${currentPrice.toStringAsFixed(0)} VND',
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(label: 'Mã sản phẩm', value: product.id),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  ProductReviewsSection(
                    productId: product.id,
                    productRatingAverage: product.ratingAverage,
                    productReviewCount: product.reviewCount,
                  ),
                  const SizedBox(height: 8),
                  if (_isLoadingRelated) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Sản Phẩm Liên Quan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.inkBrown,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SkeletonProductRail(),
                  ] else if (_relatedProducts.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Sản Phẩm Liên Quan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.inkBrown,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 252,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _relatedProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          return SizedBox(
                            width: 166,
                            child: HomeProductCard(
                              product: _relatedProducts[index],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Cost',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${currentPrice.toStringAsFixed(0)} VND',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: product.stock > 0
                    ? () {
                        cart.addProduct(product, variant: _selectedVariant);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to cart')),
                        );
                      }
                    : null,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Add to Cart'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _displayDescription(Product product) {
    final full = (product.description ?? '').trim();
    if (full.isNotEmpty) return full;
    return (product.shortDescription ?? '').trim();
  }

  List<String> _productImages(Product product) {
    final urls = <String>[];

    final thumb = resolveImageUrl(product.thumbnail);
    if (thumb.isNotEmpty) urls.add(thumb);

    for (final image in product.images) {
      final url = resolveImageUrl(image.url);
      if (url.isEmpty || urls.contains(url)) continue;
      urls.add(url);
    }

    if (urls.isEmpty) {
      urls.add('https://via.placeholder.com/900x900.png?text=Bakery+Product');
    }
    return urls;
  }

  Future<void> _openImageViewer({
    required BuildContext context,
    required List<String> images,
    required int initialIndex,
  }) async {
    var activeIndex = initialIndex;
    final controller = PageController(initialPage: initialIndex);

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: controller,
                      itemCount: images.length,
                      onPageChanged: (index) {
                        setModalState(() => activeIndex = index);
                      },
                      itemBuilder: (context, index) => Center(
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: Image.network(
                            images[index],
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image_outlined,
                              size: 42,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        color: Colors.white,
                      ),
                    ),
                    if (images.length > 1)
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Text(
                          '${activeIndex + 1}/${images.length}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    controller.dispose();
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
