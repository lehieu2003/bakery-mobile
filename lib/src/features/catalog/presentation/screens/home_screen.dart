import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/features/cart/presentation/screens/cart_screen.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/category.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/search_screen.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/widgets/home_banner_widgets.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/widgets/home_category_rail.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/widgets/home_header.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/widgets/home_product_card.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/widgets/home_subcategory_chips.dart';
import 'package:bakery_mobile/src/features/notifications/presentation/screens/notifications_screen.dart';

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
    });
    _bannerTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_bannerController.hasClients || _bannerCount <= 1) return;
      final next = (_bannerIndex + 1) % _bannerCount;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 280),
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
    final selectedRootCategory = _resolveRootCategory(
      categories: vm.categories,
      selectedCategoryId: vm.selectedCategoryId,
    );
    final subCategories = selectedRootCategory?.children ?? const <Category>[];
    _bannerCount = vm.banners.length;
    if (_bannerIndex >= _bannerCount && _bannerCount > 0) {
      _bannerIndex = 0;
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: ref.read(homeViewModelProvider.notifier).loadInitial,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            HomeHeader(
              unreadCount: notifications.unreadCount,
              onMenuTap: () => _openDrawer(context),
              onCartTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const CartScreen())),
              onNotificationTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
              onSearchTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
            ),
            const SizedBox(height: 14),
            if (vm.banners.isNotEmpty) ...[
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
              const SizedBox(height: 12),
              HomeBannerDots(
                activeIndex: _bannerIndex,
                count: vm.banners.length,
              ),
            ],
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Danh Mục Sản Phẩm',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(height: 8),
            HomeCategoryRail(
              categories: vm.categories,
              selectedCategoryId: vm.selectedCategoryId,
              onSelect: (id) =>
                  ref.read(homeViewModelProvider.notifier).selectCategory(id),
            ),
            if (subCategories.isNotEmpty) ...[
              const SizedBox(height: 8),
              HomeSubcategoryChips(
                subCategories: subCategories,
                selectedCategoryId: vm.selectedCategoryId,
                onSelect: (id) =>
                    ref.read(homeViewModelProvider.notifier).selectCategory(id),
              ),
            ],
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Sản Phẩm Nổi Bật',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            if (vm.isLoading && vm.bestSellers.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
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
                    mainAxisSpacing: 14,
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

  void _openDrawer(BuildContext context) {
    final rootScaffold = context.findRootAncestorStateOfType<ScaffoldState>();
    rootScaffold?.openDrawer();
  }
}
