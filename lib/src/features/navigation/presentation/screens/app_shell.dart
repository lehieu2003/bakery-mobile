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

    final pages = [
      const HomeScreen(),
      const ChatbotScreen(),
      const CartScreen(),
      const SearchScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Badge(
        isLabelVisible: cart.totalItems > 0,
        label: Text('${cart.totalItems}'),
        child: FloatingActionButton(
          heroTag: 'cart_fab',
          backgroundColor: AppTheme.primaryPink,
          foregroundColor: Colors.white,
          onPressed: () => setState(() => _index = 2),
          child: const Icon(Icons.shopping_cart_outlined),
        ),
      ),
      bottomNavigationBar: _BottomNavigator(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
      ),
    );
  }
}

class _BottomNavigator extends StatelessWidget {
  const _BottomNavigator({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppTheme.primaryPink,
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
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
              icon: Icons.smart_toy_outlined,
              selectedIcon: Icons.smart_toy,
              label: 'Chatbot',
              onTap: onTap,
            ),
            const SizedBox(width: 62),
            _NavButton(
              index: 3,
              currentIndex: currentIndex,
              icon: Icons.storefront_outlined,
              selectedIcon: Icons.storefront,
              label: 'Product',
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
    final fg = Colors.white;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected ? Colors.white.withValues(alpha: 0.18) : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Tooltip(
            message: label,
            child: Icon(selected ? selectedIcon : icon, size: 24, color: fg),
          ),
        ),
      ),
    );
  }
}
