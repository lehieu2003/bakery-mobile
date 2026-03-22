import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/cart/presentation/screens/cart_screen.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/home_screen.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/search_screen.dart';
import 'package:bakery_mobile/src/features/chatbot/presentation/screens/chatbot_screen.dart';
import 'package:bakery_mobile/src/features/profile/presentation/screens/profile_screen.dart';

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
      const ChatbotScreen(),
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
      margin: EdgeInsets.only(bottom: 5),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(30)),
        child: BottomAppBar(
          color: AppTheme.primaryPink,
          shape: CircularNotchedRectangle(),
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Home, Person
              Row(
                spacing: 24,
                children: [
                  _NavButton(
                    index: 0,
                    currentIndex: currentIndex,
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                    label: 'Home',
                    onTap: onTap,
                  ),
                  _NavButton(
                    index: 1,
                    currentIndex: currentIndex,
                    icon: Icons.search_outlined,
                    selectedIcon: Icons.search,
                    label: 'Search',
                    onTap: onTap,
                  ),
                ],
              ),
              // Right side: Favorite, Chatbot
              Row(
                spacing: 24,
                children: [
                  _NavButton(
                    index: 3,
                    currentIndex: currentIndex,
                    icon: Icons.chat_bubble_outline,
                    selectedIcon: Icons.chat_bubble,
                    label: 'Chatbot',
                    onTap: onTap,
                  ),
                  _NavButton(
                    index: 4,
                    currentIndex: currentIndex,
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person,
                    label: 'Profile',
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
    required this.currentIndex,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });

  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final selected = currentIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? Colors.white.withValues(alpha: 0.18) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Tooltip(
          message: label,
          child: Icon(
            selected ? selectedIcon : icon,
            size: 24,
            color: Colors.white,
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
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                displayName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.primaryPink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          _DrawerNavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            selected: currentIndex == 0,
            onTap: () => onNavigate(0),
          ),
          _DrawerNavItem(
            icon: Icons.search_outlined,
            label: 'Search',
            selected: currentIndex == 1,
            onTap: () => onNavigate(1),
          ),
          _DrawerNavItem(
            icon: Icons.shopping_cart_outlined,
            label: 'Cart',
            selected: currentIndex == 2,
            onTap: () => onNavigate(2),
          ),
          _DrawerNavItem(
            icon: Icons.chat_bubble_outline,
            label: 'Chatbot',
            selected: currentIndex == 3,
            onTap: () => onNavigate(3),
          ),
          _DrawerNavItem(
            icon: Icons.person_outline,
            label: 'Profile',
            selected: currentIndex == 4,
            onTap: () => onNavigate(4),
          ),
          const Spacer(),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: onLogout == null
                ? null
                : () {
                    Navigator.of(context).pop();
                    onLogout?.call();
                  },
          ),
          const SizedBox(height: 12),
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
