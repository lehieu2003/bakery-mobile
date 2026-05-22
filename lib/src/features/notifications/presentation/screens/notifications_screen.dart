import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/widgets/skeleton_widgets.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsViewModelProvider.notifier).load();
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
      ref.read(notificationsViewModelProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    final vm = ref.watch(notificationsViewModelProvider);

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
            onPressed: vm.unreadCount > 0
                ? ref
                      .read(notificationsViewModelProvider.notifier)
                      .markAllAsRead
                : null,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: ref.read(notificationsViewModelProvider.notifier).load,
        child: ListView(
          controller: _scrollController,
          children: [
            if (vm.isLoading && vm.notifications.isEmpty)
              const Column(
                children: [
                  SkeletonNotificationTile(),
                  SkeletonNotificationTile(),
                  SkeletonNotificationTile(),
                  SkeletonNotificationTile(),
                  SkeletonNotificationTile(),
                ],
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
                        onPressed: () => ref
                            .read(notificationsViewModelProvider.notifier)
                            .markOneAsRead(n.id),
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
                  onPressed: ref
                      .read(notificationsViewModelProvider.notifier)
                      .loadMore,
                  child: const Text('Load more'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
