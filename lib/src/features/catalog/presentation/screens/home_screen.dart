import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/core/utils/image_url.dart';
import 'package:bakery_mobile/src/features/cart/presentation/screens/cart_screen.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/category.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/search_screen.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/widgets/home_product_card.dart';
import 'package:bakery_mobile/src/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:bakery_mobile/src/features/pages/presentation/screens/pages_screen.dart';

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
            _HomeHeader(
              unreadCount: notifications.unreadCount,
              onMenuTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PagesScreen())),
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
                    itemBuilder: (context, index) => _HeroBanner(
                      title: vm.banners[index].title,
                      imageUrl: vm.banners[index].imageUrl,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _BannerDots(activeIndex: _bannerIndex, count: vm.banners.length),
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
            _CategoryRail(
              categories: vm.categories,
              selectedCategoryId: vm.selectedCategoryId,
              onSelect: (id) =>
                  ref.read(homeViewModelProvider.notifier).selectCategory(id),
            ),
            if (subCategories.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Danh Mục Con',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  scrollDirection: Axis.horizontal,
                  children: subCategories
                      .map(
                        (subcategory) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              subcategory.children.isNotEmpty
                                  ? '${subcategory.name} (${subcategory.children.length})'
                                  : subcategory.name,
                            ),
                            selected: vm.selectedCategoryId == subcategory.id,
                            onSelected: (_) => ref
                                .read(homeViewModelProvider.notifier)
                                .selectCategory(subcategory.id),
                          ),
                        ),
                      )
                      .toList(),
                ),
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
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.unreadCount,
    required this.onMenuTap,
    required this.onCartTap,
    required this.onNotificationTap,
    required this.onSearchTap,
  });

  final int unreadCount;
  final VoidCallback onMenuTap;
  final VoidCallback onCartTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        MediaQuery.paddingOf(context).top + 10,
        14,
        20,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.primaryPink,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(56)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onMenuTap,
                icon: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const Spacer(),
              _HeaderSquareButton(
                icon: Icons.shopping_cart_outlined,
                onTap: onCartTap,
              ),
              const SizedBox(width: 10),
              Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: _HeaderSquareButton(
                  icon: Icons.notifications_none_rounded,
                  onTap: onNotificationTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: onSearchTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: double.infinity,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.76),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(Icons.search_rounded, color: Color(0xFF8C8C8C)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderSquareButton extends StatelessWidget {
  const _HeaderSquareButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({this.title, this.imageUrl});

  final String? title;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (resolveImageUrl(imageUrl).isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                resolveImageUrl(imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          if (resolveImageUrl(imageUrl).isNotEmpty)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.black.withValues(alpha: 0.16),
              ),
            ),
          if (title != null && title!.isNotEmpty)
            Positioned(
              left: 18,
              bottom: 18,
              right: 18,
              child: Text(
                title!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BannerDots extends StatelessWidget {
  const _BannerDots({required this.activeIndex, required this.count});

  final int activeIndex;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == activeIndex;
        return Container(
          width: active ? 10 : 8,
          height: active ? 10 : 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppTheme.primaryPink : const Color(0xFFD0D0D0),
          ),
        );
      }),
    );
  }
}

class _CategoryRail extends StatelessWidget {
  const _CategoryRail({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelect,
  });

  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        children: [
          ...categories.map(
            (category) => _CategoryCapsule(
              label: category.name,
              imageUrl: category.imageUrl,
              isSelected: _isRootSelected(category, selectedCategoryId),
              onTap: () => onSelect(category.id),
            ),
          ),
        ],
      ),
    );
  }

  bool _isRootSelected(Category root, String? selectedId) {
    if (selectedId == null) return false;
    if (root.id == selectedId) return true;
    return _contains(root.children, selectedId);
  }

  bool _contains(List<Category> children, String selectedId) {
    for (final category in children) {
      if (category.id == selectedId) return true;
      if (_contains(category.children, selectedId)) return true;
    }
    return false;
  }
}

class _CategoryCapsule extends StatelessWidget {
  const _CategoryCapsule({
    required this.label,
    required this.imageUrl,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String? imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 64,
          child: Column(
            children: [
              Container(
                width: 54,
                height: 82,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryPink
                      : const Color(0xFFD3D3D3),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 7),
                    ClipOval(
                      child: Container(
                        width: 34,
                        height: 34,
                        color: Colors.white.withValues(alpha: 0.68),
                        child: resolveImageUrl(imageUrl).isNotEmpty
                            ? Image.network(
                                resolveImageUrl(imageUrl),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              )
                            : null,
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
