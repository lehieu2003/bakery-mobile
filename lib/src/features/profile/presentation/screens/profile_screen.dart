import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bakery_mobile/src/features/blog/presentation/screens/blog_screen.dart';
import 'package:bakery_mobile/src/features/chatbot/presentation/screens/chatbot_screen.dart';
import 'package:bakery_mobile/src/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:bakery_mobile/src/features/pages/presentation/screens/pages_screen.dart';
import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:bakery_mobile/src/features/notifications/presentation/controllers/notifications_view_model.dart';
import 'package:bakery_mobile/src/features/orders/presentation/controllers/orders_view_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersViewModel>().loadMyOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final orders = context.watch<OrdersViewModel>();
    final notifications = context.watch<NotificationsViewModel>();

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
            onPressed: auth.isSubmitting ? null : auth.logout,
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
                onPressed: orders.isLoading ? null : orders.loadMyOrders,
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
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('No orders yet.'),
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


