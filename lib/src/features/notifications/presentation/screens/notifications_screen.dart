import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:bakery_mobile/src/features/notifications/presentation/controllers/notifications_view_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsViewModel>().load();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 180;
    if (_scrollController.position.pixels >= threshold) {
      context.read<NotificationsViewModel>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final vm = context.watch<NotificationsViewModel>();

    if (!auth.isAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view notifications.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications (${vm.unreadCount})'),
        actions: [
          TextButton(
            onPressed: vm.unreadCount > 0 ? vm.markAllAsRead : null,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          controller: _scrollController,
          children: [
            if (vm.isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (vm.error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  vm.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (!vm.isLoading && vm.notifications.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No notifications.')),
              ),
            ...vm.notifications.map(
              (n) => ListTile(
                leading: Icon(
                  n.isRead
                      ? Icons.mark_email_read_outlined
                      : Icons.mark_email_unread_outlined,
                ),
                title: Text(n.title),
                subtitle: Text(n.content),
                trailing: n.isRead
                    ? null
                    : TextButton(
                        onPressed: () => vm.markOneAsRead(n.id),
                        child: const Text('Read'),
                      ),
              ),
            ),
            if (vm.isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!vm.isLoading && !vm.isLoadingMore && vm.hasMore)
              Padding(
                padding: const EdgeInsets.all(12),
                child: OutlinedButton(
                  onPressed: vm.loadMore,
                  child: const Text('Load more'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


