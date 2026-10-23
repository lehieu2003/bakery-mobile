import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_banner_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_category_rail_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_product_grid_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/empty_state_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/catalog_keys.dart';
import 'package:bakery_mobile/src/features/cart/presentation/screens/cart_screen.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/category_screen.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/controllers/home_view_model.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/search_screen.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/widgets/home_banner_dots.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/widgets/home_hero_banner.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/widgets/home_category_rail.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/widgets/home_header.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/widgets/home_product_card.dart';
import 'package:bakery_mobile/src/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:bakery_mobile/src/features/wishlist/presentation/screens/wishlist_screen.dart';
import 'package:bakery_mobile/src/core/theme/app_durations.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/shared/utils/motion.dart';

/// Bottom space so the last content clears the floating navigation bar.
const double _navBarClearance = 96;

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
      // Both endpoints require a session; guests would only get a 401.
      if (!ref.read(authViewModelProvider).isAuthenticated) return;
      ref.read(notificationsViewModelProvider.notifier).load();
      ref.read(wishlistViewModelProvider.notifier).load();
    });
    _bannerTimer = Timer.periodic(AppDurations.carouselAutoplay, (_) {
      if (!mounted || !allowsAutoplay(context)) return;
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
          key: HomeKeys.list,
          padding: const EdgeInsets.only(bottom: _navBarClearance),
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
            const Gap(AppSpacing.md),
            if (showInitialSkeleton) ...[
              const SkeletonBannerWidget(),
              const Gap(AppSpacing.md),
            ] else if (vm.banners.isNotEmpty) ...[
              Padding(
                key: HomeKeys.banners,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: SizedBox(
                  height: 190,
                  // A swipe hands the banners to the user: autoplay stops
                  // for good instead of moving them on again.
                  child: NotificationListener<UserScrollNotification>(
                    onNotification: (_) {
                      _bannerTimer?.cancel();
                      return false;
                    },
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
              ),
              const Gap(AppSpacing.md),
              HomeBannerDots(
                activeIndex: _bannerIndex,
                count: vm.banners.length,
              ),
            ],
            const Gap(AppSpacing.md),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _HomeSectionTitle(
                title: 'Danh Mục Sản Phẩm',
                icon: Icons.grid_view_rounded,
              ),
            ),
            const Gap(AppSpacing.sm),
            if (showInitialSkeleton)
              const SkeletonCategoryRailWidget()
            else
              HomeCategoryRail(
                key: HomeKeys.categoryRail,
                categories: vm.categories,
                onSelect: (category) => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CategoryScreen(category: category),
                  ),
                ),
              ),
            const Gap(AppSpacing.md),
            if (vm.personalizedProducts.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: _HomeSectionTitle(
                  title: 'Gợi Ý Dành Cho Bạn',
                  icon: Icons.favorite_rounded,
                ),
              ),
              if (_personalizedMessage(vm) != null)
                Padding(
                  key: HomeKeys.personalizedMessage,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Text(
                    _personalizedMessage(vm)!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                  ),
                ),
              Padding(
                key: HomeKeys.personalized,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vm.personalizedProducts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.lg,
                    crossAxisSpacing: AppSpacing.lg,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, index) => HomeProductCard(
                    key: HomeKeys.personalizedItem(
                      vm.personalizedProducts[index].id,
                    ),
                    product: vm.personalizedProducts[index],
                  ),
                ),
              ),
              const Gap(AppSpacing.md),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _HomeSectionTitle(
                title: 'Sản Phẩm Nổi Bật',
                icon: Icons.auto_awesome_rounded,
              ),
            ),
            if (showInitialSkeleton)
              const SkeletonProductGridWidget(key: HomeKeys.loading),
            if (vm.errorMessage != null &&
                vm.bestSellers.isEmpty &&
                !vm.isLoading)
              ErrorRetryWidget(
                key: HomeKeys.error,
                message: vm.errorMessage!,
                onRetry: ref.read(homeViewModelProvider.notifier).loadInitial,
              ),
            if (vm.errorMessage != null && vm.bestSellers.isNotEmpty)
              Padding(
                key: HomeKeys.errorBanner,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  0,
                ),
                child: Text(
                  vm.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (!vm.isLoading &&
                vm.errorMessage == null &&
                vm.bestSellers.isEmpty)
              const EmptyStateWidget(
                key: HomeKeys.empty,
                message: 'Chưa có sản phẩm nổi bật.',
              ),
            if (vm.bestSellers.isNotEmpty)
              Padding(
                key: HomeKeys.bestSellers,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: 0,
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vm.bestSellers.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.lg,
                    crossAxisSpacing: AppSpacing.lg,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, index) => HomeProductCard(
                    key: HomeKeys.bestSeller(vm.bestSellers[index].id),
                    product: vm.bestSellers[index],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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
            const Gap(AppSpacing.sm),
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
        const Gap(AppSpacing.sm),
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
