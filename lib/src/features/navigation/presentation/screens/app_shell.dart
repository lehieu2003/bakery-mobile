import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/features/auth/presentation/screens/auth_screen.dart';
import 'package:bakery_mobile/src/features/cart/presentation/screens/cart_screen.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/home_screen.dart';
import 'package:bakery_mobile/src/features/profile/presentation/screens/profile_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authViewModelProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = ref.watch(authViewModelProvider);
    final cart = ref.watch(cartViewModelProvider);
    final notifications = ref.watch(notificationsViewModelProvider);

    if (authViewModel.isAuthenticated &&
        !notifications.isLoading &&
        notifications.notifications.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(notificationsViewModelProvider.notifier).load();
      });
    }

    if (authViewModel.isBootstrapping) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = [
      const HomeScreen(),
      const CartScreen(),
      authViewModel.isAuthenticated
          ? const ProfileScreen()
          : const AuthScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cart.totalItems > 0,
              label: Text('${cart.totalItems}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cart.totalItems > 0,
              label: Text('${cart.totalItems}'),
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(
              authViewModel.isAuthenticated
                  ? Icons.person_outline
                  : Icons.login_outlined,
            ),
            selectedIcon: Icon(
              authViewModel.isAuthenticated ? Icons.person : Icons.login,
            ),
            label: authViewModel.isAuthenticated ? 'Profile' : 'Auth',
          ),
        ],
      ),
    );
  }
}
