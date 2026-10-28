import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/cart/presentation/screens/cart_screen.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/home_screen.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/search_screen.dart';
import 'package:bakery_mobile/src/features/profile/presentation/screens/profile_screen.dart';
import 'package:bakery_mobile/src/features/wishlist/presentation/screens/wishlist_screen.dart';
import 'package:bakery_mobile/src/shared/widgets/initial_avatar_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_durations.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

/// Top corners of the bottom navigation bar.
const double _navBarRadius = 30;

/// Minimum touch target of a bottom tab (Material 48dp).
const double _navTargetSize = 48;

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartViewModelProvider);
    final auth = ref.watch(authViewModelProvider);
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final hideShellChrome = keyboardVisible;

    final pages = [
      const HomeScreen(),
      const SearchScreen(),
      const CartScreen(),
      const WishlistScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      drawer: _AppDrawer(
        currentIndex: _index,
        userName: auth.user?.name,
        userEmail: auth.user?.email,
        onNavigate: _onDrawerNavigate,
        onLogout: auth.isSubmitting
            ? null
            : () => ref.read(authViewModelProvider.notifier).logout(),
      ),
      body: IndexedStack(index: _index, children: pages),
      floatingActionButtonLocation: hideShellChrome
          ? null
          : FloatingActionButtonLocation.centerDocked,
      floatingActionButton: hideShellChrome
          ? null
          : Badge(
              isLabelVisible: cart.totalItems > 0,
              label: Text('${cart.totalItems}'),
              child: FloatingActionButton(
                tooltip: cart.totalItems > 0
                    ? 'Giỏ hàng, ${cart.totalItems} sản phẩm'
                    : 'Giỏ hàng',
                shape: const StadiumBorder(),
                heroTag: 'cart_fab',
                backgroundColor: AppTheme.primaryPink,
                foregroundColor: Colors.white,
                elevation: 0,
                onPressed: () => setState(() => _index = 2),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
      bottomNavigationBar: hideShellChrome
          ? null
          : _BottomNavigator(
              currentIndex: _index,
              onTap: (value) => setState(() => _index = value),
            ),
    );
  }

  void _onDrawerNavigate(int index) {
    Navigator.of(context).pop();
    if (_index == index) return;
    setState(() => _index = index);
  }
}

class _BottomNavigator extends StatelessWidget {
  const _BottomNavigator({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.xs),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(_navBarRadius)),
        child: BottomAppBar(
          color: AppTheme.primaryPink,
          shape: CircularNotchedRectangle(),
          height: 60,
          // No vertical padding: the 48dp tab targets need the full height.
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Home, Person
              Row(
                spacing: AppSpacing.xxl,
                children: [
                  _NavButton(
                    index: 0,
                    label: 'Trang chủ',
                    currentIndex: currentIndex,
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                    onTap: onTap,
                  ),
                  _NavButton(
                    index: 1,
                    label: 'Tìm kiếm',
                    currentIndex: currentIndex,
                    icon: Icons.search_outlined,
                    selectedIcon: Icons.search,
                    onTap: onTap,
                  ),
                ],
              ),
              // Right side: Favorite, Profile
              Row(
                spacing: AppSpacing.xxl,
                children: [
                  _NavButton(
                    index: 3,
                    label: 'Yêu thích',
                    currentIndex: currentIndex,
                    icon: Icons.favorite_border,
                    selectedIcon: Icons.favorite,
                    onTap: onTap,
                  ),
                  _NavButton(
                    index: 4,
                    label: 'Tài khoản',
                    currentIndex: currentIndex,
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person,
                    onTap: onTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.index,
    required this.label,
    required this.currentIndex,
    required this.icon,
    required this.selectedIcon,
    required this.onTap,
  });

  final int index;

  /// Spoken by screen readers only; the tab stays icon-only on screen.
  final String label;
  final int currentIndex;
  final IconData icon;
  final IconData selectedIcon;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = currentIndex == index;

    // Icon-only on screen by design (no visible labels or tooltips), but
    // screen readers announce each tab's name and selected state, and the
    // touch target is 48dp around the visible pill.
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: () => onTap(index),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: _navTargetSize,
            minHeight: _navTargetSize,
          ),
          child: Center(
            child: AnimatedContainer(
              duration: AppDurations.fast,
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                color: selected ? AppTheme.navSelectedHighlight : null,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Icon(
                selected ? selectedIcon : icon,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.currentIndex,
    required this.onNavigate,
    required this.onLogout,
    this.userName,
    this.userEmail,
  });

  final int currentIndex;
  final String? userName;
  final String? userEmail;
  final ValueChanged<int> onNavigate;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final displayName = (userName?.trim().isNotEmpty ?? false)
        ? userName!.trim()
        : 'Bakery Customer';
    final displayEmail = (userEmail?.trim().isNotEmpty ?? false)
        ? userEmail!.trim()
        : 'Guest';

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primaryPink),
            accountName: Text(displayName),
            accountEmail: Text(displayEmail),
            currentAccountPicture: InitialAvatarWidget(
              name: displayName,
              radius: 36,
              backgroundColor: AppTheme.surfaceWhite,
              foregroundColor: AppTheme.primaryPink,
            ),
          ),
          _DrawerNavItem(
            icon: Icons.home_outlined,
            label: 'Trang chủ',
            selected: currentIndex == 0,
            onTap: () => onNavigate(0),
          ),
          _DrawerNavItem(
            icon: Icons.search_outlined,
            label: 'Tìm kiếm',
            selected: currentIndex == 1,
            onTap: () => onNavigate(1),
          ),
          _DrawerNavItem(
            icon: Icons.shopping_cart_outlined,
            label: 'Giỏ hàng',
            selected: currentIndex == 2,
            onTap: () => onNavigate(2),
          ),
          _DrawerNavItem(
            icon: Icons.favorite_border,
            label: 'Yêu thích',
            selected: currentIndex == 3,
            onTap: () => onNavigate(3),
          ),
          _DrawerNavItem(
            icon: Icons.person_outline,
            label: 'Tài khoản',
            selected: currentIndex == 4,
            onTap: () => onNavigate(4),
          ),
          const Spacer(),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Đăng xuất'),
            onTap: onLogout == null
                ? null
                : () {
                    Navigator.of(context).pop();
                    onLogout?.call();
                  },
          ),
          const Gap(AppSpacing.md),
        ],
      ),
    );
  }
}

class _DrawerNavItem extends StatelessWidget {
  const _DrawerNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: selected,
      onTap: onTap,
    );
  }
}
