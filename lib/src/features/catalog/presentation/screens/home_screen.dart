import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_banner_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_category_rail_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_product_grid_widget.dart';
import 'package:bakery_mobile/src/features/cart/presentation/screens/cart_screen.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/category.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/controllers/home_view_model.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/search_screen.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/widgets/home_banner_dots.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/widgets/home_hero_banner.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/widgets/home_category_rail.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/widgets/home_header.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/widgets/home_product_card.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/widgets/home_subcategory_chips.dart';
import 'package:bakery_mobile/src/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:bakery_mobile/src/features/wishlist/presentation/screens/wishlist_screen.dart';
import 'package:bakery_mobile/src/core/theme/app_durations.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _HomeView();
  }
}

class _HomeView extends ConsumerStatefulWidget {
  const _HomeView();

  @override
  ConsumerState<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<_HomeView> {
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _bannerIndex = 0;
  int _bannerCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeViewModelProvider.notifier).loadInitial();
      ref.read(notificationsViewModelProvider.notifier).load();
      ref.read(wishlistViewModelProvider.notifier).load();
    });
    _bannerTimer = Timer.periodic(AppDurations.carouselAutoplay, (_) {
      if (!_bannerController.hasClients || _bannerCount <= 1) return;
      final next = (_bannerIndex + 1) % _bannerCount;
      _bannerController.animateToPage(
        next,
        duration: AppDurations.medium,
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(homeViewModelProvider);
    final notifications = ref.watch(notificationsViewModelProvider);
    final wishlist = ref.watch(wishlistViewModelProvider);
    final selectedRootCategory = _resolveRootCategory(
      categories: vm.categories,
      selectedCategoryId: vm.selectedCategoryId,
    );
    final subCategories = selectedRootCategory?.children ?? const <Category>[];
    _bannerCount = vm.banners.length;
    if (_bannerIndex >= _bannerCount && _bannerCount > 0) {
      _bannerIndex = 0;
    }
    final showInitialSkeleton = vm.isLoading && vm.bestSellers.isEmpty;

    return Scaffold(
      backgroundColor: AppTheme.canvasCream,
      body: RefreshIndicator(
        onRefresh: ref.read(homeViewModelProvider.notifier).loadInitial,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            HomeHeader(
              unreadCount: notifications.unreadCount,
              favoriteCount: wishlist.items.length,
              onMenuTap: () => _openDrawer(context),
              onCartTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const CartScreen())),
              onNotificationTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
              onFavoriteTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const WishlistScreen())),
              onSearchTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
            ),
            const SizedBox(height: 12),
            if (showInitialSkeleton) ...[
              const SkeletonBannerWidget(),
              const SizedBox(height: 10),
            ] else if (vm.banners.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: SizedBox(
                  height: 190,
                  child: PageView.builder(
                    controller: _bannerController,
                    itemCount: vm.banners.length,
                    onPageChanged: (value) =>
                        setState(() => _bannerIndex = value),
                    itemBuilder: (context, index) => HomeHeroBanner(
                      title: vm.banners[index].title,
                      imageUrl: vm.banners[index].imageUrl,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              HomeBannerDots(
                activeIndex: _bannerIndex,
                count: vm.banners.length,
              ),
            ],
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _HomeSectionTitle(
                title: 'Danh Mục Sản Phẩm',
                icon: Icons.grid_view_rounded,
              ),
            ),
            const SizedBox(height: 6),
            if (showInitialSkeleton)
              const SkeletonCategoryRailWidget()
            else
              HomeCategoryRail(
                categories: vm.categories,
                selectedCategoryId: vm.selectedCategoryId,
                onSelect: (id) =>
                    ref.read(homeViewModelProvider.notifier).selectCategory(id),
              ),
            if (subCategories.isNotEmpty) ...[
              const SizedBox(height: 6),
              HomeSubcategoryChips(
                subCategories: subCategories,
                selectedCategoryId: vm.selectedCategoryId,
                onSelect: (id) =>
                    ref.read(homeViewModelProvider.notifier).selectCategory(id),
              ),
            ],
            const SizedBox(height: 12),
            if (vm.personalizedProducts.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _HomeSectionTitle(
                  title: 'Gợi Ý Dành Cho Bạn',
                  icon: Icons.favorite_rounded,
                ),
              ),
              if (_personalizedMessage(vm) != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Text(
                    _personalizedMessage(vm)!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vm.personalizedProducts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, index) =>
                      HomeProductCard(product: vm.personalizedProducts[index]),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _HomeSectionTitle(
                title: 'Sản Phẩm Nổi Bật',
                icon: Icons.auto_awesome_rounded,
              ),
            ),
            if (showInitialSkeleton) const SkeletonProductGridWidget(),
            if (vm.errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Text(
                  vm.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (vm.bestSellers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 0,
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vm.bestSellers.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, index) =>
                      HomeProductCard(product: vm.bestSellers[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Category? _resolveRootCategory({
    required List<Category> categories,
    required String? selectedCategoryId,
  }) {
    if (selectedCategoryId == null) return null;
    for (final root in categories) {
      if (root.id == selectedCategoryId) {
        return root;
      }
      if (_containsCategoryId(root.children, selectedCategoryId)) {
        return root;
      }
    }
    return null;
  }

  bool _containsCategoryId(List<Category> categories, String targetId) {
    for (final category in categories) {
      if (category.id == targetId) return true;
      if (_containsCategoryId(category.children, targetId)) return true;
    }
    return false;
  }

  String? _personalizedMessage(HomeState vm) {
    if (vm.personalizedSource == null ||
        vm.personalizedSource == 'behavioral') {
      return null;
    }

    switch (vm.personalizedReason) {
      case 'no-user':
        return 'Sign in to unlock personalized suggestions. Showing featured picks for now.';
      case 'insufficient-signal':
        return 'Showing a mix of personalized picks and featured products.';
      default:
        return null;
    }
  }

  void _openDrawer(BuildContext context) {
    final rootScaffold = context.findRootAncestorStateOfType<ScaffoldState>();
    rootScaffold?.openDrawer();
  }
}

class _HomeSectionTitle extends StatelessWidget {
  const _HomeSectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.peachTint,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Icon(icon, size: 16, color: AppTheme.warmBrown),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.warmBrown,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: 54,
          height: 3,
          decoration: BoxDecoration(
            color: AppTheme.blushPink.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ],
    );
  }
}
