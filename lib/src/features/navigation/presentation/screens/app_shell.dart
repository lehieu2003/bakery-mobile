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
      const ProfileScreen(),
      const CartScreen(),
      const SearchScreen(),
      const ChatbotScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: pages),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Badge(
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
      bottomNavigationBar: _BottomNavigator(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
      ),
    );
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
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person,
                    label: 'Profile',
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
                    icon: Icons.search_outlined,
                    selectedIcon: Icons.search,
                    label: 'Search',
                    onTap: onTap,
                  ),
                  _NavButton(
                    index: 4,
                    currentIndex: currentIndex,
                    icon: Icons.chat_bubble_outline,
                    selectedIcon: Icons.chat_bubble,
                    label: 'Chatbot',
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
