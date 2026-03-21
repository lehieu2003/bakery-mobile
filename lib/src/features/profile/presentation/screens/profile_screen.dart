import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/features/blog/presentation/screens/blog_screen.dart';
import 'package:bakery_mobile/src/features/chatbot/presentation/screens/chatbot_screen.dart';
import 'package:bakery_mobile/src/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:bakery_mobile/src/features/pages/presentation/screens/pages_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    final orders = ref.watch(ordersViewModelProvider);
    final notifications = ref.watch(notificationsViewModelProvider);

    final user = auth.user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to see your profile.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: auth.isSubmitting
                ? null
                : ref.read(authViewModelProvider.notifier).logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: Text(user.name ?? 'Customer'),
              subtitle: Text(
                '${user.email}/nLevel: ${user.memberLevel ?? 'SILVER'} | Points: ${user.points ?? 0}',
              ),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(
                    'Notifications (${notifications.unreadCount} unread)',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: const Text('Blog'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BlogScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: const Text('Chatbot'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: const Text('Policy & Pages'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PagesScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Orders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: orders.isLoading
                    ? null
                    : ref.read(ordersViewModelProvider.notifier).loadMyOrders,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (orders.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          if (orders.errorMessage != null)
            Text(
              orders.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (!orders.isLoading && orders.orders.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Expanded(child: Text('No orders loaded yet.')),
                  TextButton(
                    onPressed: () =>
                        ref.read(ordersViewModelProvider.notifier).loadMyOrders(),
                    child: const Text('Load'),
                  ),
                ],
              ),
            ),
          ...orders.orders.map(
            (order) => Card(
              child: ListTile(
                title: Text('#${order.orderNumber}'),
                subtitle: Text(
                  '${order.status} - ${order.createdAt.toLocal()}/n${order.orderItems.isNotEmpty ? order.orderItems.first.name : ''}',
                ),
                trailing: Text('${order.total.toStringAsFixed(0)} VND'),
                isThreeLine: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
