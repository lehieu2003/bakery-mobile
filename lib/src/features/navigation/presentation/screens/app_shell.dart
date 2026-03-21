import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bakery_mobile/src/features/auth/presentation/screens/auth_screen.dart';
import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:bakery_mobile/src/features/cart/presentation/screens/cart_screen.dart';
import 'package:bakery_mobile/src/features/cart/presentation/controllers/cart_view_model.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/home_screen.dart';
import 'package:bakery_mobile/src/features/notifications/presentation/controllers/notifications_view_model.dart';
import 'package:bakery_mobile/src/features/profile/presentation/screens/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final cart = context.watch<CartViewModel>();
    final notifications = context.watch<NotificationsViewModel>();

    if (authViewModel.isAuthenticated &&
        !notifications.isLoading &&
        notifications.notifications.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<NotificationsViewModel>().load();
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


