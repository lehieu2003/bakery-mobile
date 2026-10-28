import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/core/utils/image_url.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_product_detail_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_product_rail_widget.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/widgets/home_product_card.dart';
import 'package:bakery_mobile/src/features/reviews/presentation/widgets/product_reviews_section.dart';
import 'package:bakery_mobile/src/shared/widgets/app_network_image_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/discount_badge_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/price_widget.dart';
import 'package:bakery_mobile/src/shared/utils/format_utils.dart';
import 'package:bakery_mobile/src/shared/widgets/summary_row_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/favorite_icon_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_durations.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/shared/utils/error_message.dart';
import 'package:bakery_mobile/src/shared/utils/motion.dart';
import 'package:bakery_mobile/src/features/cart/presentation/widgets/added_to_cart_snack_bar.dart';

/// Bottom space so content clears the pinned price/"Add to Cart" bar.
const double _bottomBarClearance = 120;

/// Products shown in the "related" strip under the details.
const int _relatedProductsShown = 8;

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
    _imageTimer = Timer.periodic(AppDurations.carouselAutoplay, (_) {
      if (!mounted || !allowsAutoplay(context)) return;
      final product = _product;
      if (product == null) return;
      final images = _productImages(product);
      if (!_imageController.hasClients || images.length <= 1) return;
      final next = (_activeImageIndex + 1) % images.length;
      _imageController.animateToPage(
        next,
        duration: AppDurations.medium,
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
      unawaited(ref.read(reviewsViewModelProvider(product.id).notifier).load());
      unawaited(_loadRelatedProducts(product));
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = userErrorMessage(error));
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
            .take(_relatedProductsShown)
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
      return const SkeletonProductDetailWidget();
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error!)),
      );
    }

    final product = _product;
    if (product == null) {
      return const Scaffold(
        body: Center(child: Text('Không tìm thấy sản phẩm')),
      );
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
            backgroundColor: AppTheme.surfaceWhite,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              tooltip: 'Quay lại',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              IconButton(
                tooltip: isFavorite ? 'Bỏ yêu thích' : 'Thêm vào yêu thích',
                onPressed: isPendingFavorite
                    ? null
                    : () => wishlistNotifier.toggle(product),
                icon: FavoriteIconWidget(
                  isFavorite: isFavorite,
                  isPending: isPendingFavorite,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // A swipe hands the gallery to the user: autoplay stops.
                  NotificationListener<UserScrollNotification>(
                    onNotification: (_) {
                      _imageTimer?.cancel();
                      return false;
                    },
                    child: PageView.builder(
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
                        child: AppNetworkImageWidget(
                          url: images[index],
                          backgroundColor: AppTheme.placeholderBeige,
                          iconSize: 40,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 88,
                    left: 16,
                    child: detailDiscount == null
                        ? const SizedBox.shrink()
                        : DiscountBadgeWidget(
                            percent: detailDiscount,
                            variant: DiscountBadgeVariant.large,
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
                          duration: AppDurations.fast,
                          width: active ? 18 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? AppTheme.surfaceWhite
                                : AppTheme.carouselDotInactive,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                _bottomBarClearance,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(AppSpacing.sm),
                  Row(
                    children: [
                      Flexible(
                        child: PriceWidget(
                          price: currentPrice,
                          comparePrice: detailDiscount != null
                              ? originalPrice
                              : null,
                          variant: PriceVariant.detail,
                        ),
                      ),
                      const Gap(AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: product.stock > 0
                              ? AppTheme.stockAvailableBg
                              : AppTheme.stockOutBg,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          product.stock > 0
                              ? 'Còn ${product.stock} sản phẩm'
                              : 'Hết hàng',
                          style: TextStyle(
                            color: product.stock > 0
                                ? AppTheme.stockAvailableText
                                : AppTheme.stockOutText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(AppSpacing.lg),
                  if (summaryText.isNotEmpty) ...[
                    Text(
                      'Mô tả sản phẩm',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(AppSpacing.sm),
                    Text(
                      summaryText,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.45),
                    ),
                    const Gap(AppSpacing.xl),
                  ],
                  if (hasVariants) ...[
                    Text(
                      'Biến thể',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: product.variants
                          .map(
                            (variant) => ChoiceChip(
                              label: Text(
                                '${variant.name} - ${formatVnd(variant.price)}',
                              ),
                              selected: _selectedVariant?.id == variant.id,
                              onSelected: (_) =>
                                  setState(() => _selectedVariant = variant),
                            ),
                          )
                          .toList(),
                    ),
                    const Gap(AppSpacing.xl),
                  ],
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Column(
                      children: [
                        if (detailDiscount != null) ...[
                          SummaryRowWidget(
                            variant: SummaryRowVariant.emphasis,
                            label: 'Giá trước ưu đãi',
                            value: formatVnd(originalPrice!),
                          ),
                          const Gap(AppSpacing.sm),
                          SummaryRowWidget(
                            variant: SummaryRowVariant.emphasis,
                            label: 'Ưu đãi',
                            value: '-$detailDiscount%',
                          ),
                          const Gap(AppSpacing.sm),
                        ],
                        SummaryRowWidget(
                          variant: SummaryRowVariant.emphasis,
                          label: 'Giá đang chọn',
                          value: formatVnd(currentPrice),
                        ),
                        const Gap(AppSpacing.sm),
                        SummaryRowWidget(
                          variant: SummaryRowVariant.emphasis,
                          label: 'Mã sản phẩm',
                          value: product.id,
                        ),
                      ],
                    ),
                  ),
                  const Gap(AppSpacing.lg),
                  const Divider(),
                  const Gap(AppSpacing.sm),
                  ProductReviewsSection(
                    productId: product.id,
                    productRatingAverage: product.ratingAverage,
                    productReviewCount: product.reviewCount,
                  ),
                  const Gap(AppSpacing.sm),
                  if (_isLoadingRelated) ...[
                    const Gap(AppSpacing.xl),
                    Text(
                      'Sản Phẩm Liên Quan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.inkBrown,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Gap(AppSpacing.md),
                    const SkeletonProductRailWidget(),
                  ] else if (_relatedProducts.isNotEmpty) ...[
                    const Gap(AppSpacing.xl),
                    Text(
                      'Sản Phẩm Liên Quan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.inkBrown,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Gap(AppSpacing.md),
                    SizedBox(
                      height: 252,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _relatedProducts.length,
                        separatorBuilder: (_, __) => const Gap(AppSpacing.md),
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
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowBottomBar,
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
                      'Tổng tiền',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      formatVnd(currentPrice),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.md),
              FilledButton.icon(
                onPressed: product.stock > 0
                    ? () {
                        cart.addProduct(product, variant: _selectedVariant);
                        showAddedToCartSnackBar(context, product.name);
                      }
                    : null,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Thêm vào giỏ'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.lg,
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
      barrierColor: AppTheme.scrimImageViewer,
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
                          child: AppNetworkImageWidget(
                            url: images[index],
                            fit: BoxFit.contain,
                            backgroundColor: Colors.transparent,
                            iconSize: 42,
                            iconColor: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        tooltip: 'Đóng',
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
