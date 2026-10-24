import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_notification_tile_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/loading_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/features/notifications/presentation/notifications_keys.dart';
import 'package:bakery_mobile/src/shared/widgets/empty_state_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';

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
      // Guests only see the sign-in prompt; the API would answer 401.
      if (!ref.read(authViewModelProvider).isAuthenticated) return;
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
        body: Center(child: Text('Đăng nhập để xem thông báo.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Thông báo (${vm.unreadCount})'),
        actions: [
          TextButton(
            key: NotificationsKeys.markAllRead,
            onPressed: vm.unreadCount > 0
                ? ref
                      .read(notificationsViewModelProvider.notifier)
                      .markAllAsRead
                : null,
            child: const Text('Đọc tất cả'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: ref.read(notificationsViewModelProvider.notifier).load,
        child: ListView(
          key: NotificationsKeys.list,
          controller: _scrollController,
          children: [
            if (vm.isLoading && vm.notifications.isEmpty)
              const Column(
                key: NotificationsKeys.loading,
                children: [
                  SkeletonNotificationTileWidget(),
                  SkeletonNotificationTileWidget(),
                  SkeletonNotificationTileWidget(),
                  SkeletonNotificationTileWidget(),
                  SkeletonNotificationTileWidget(),
                ],
              ),
            // Nothing to show and the load failed: error + retry (instead of
            // the empty message, which would claim there are none).
            if (vm.error != null && vm.notifications.isEmpty && !vm.isLoading)
              ErrorRetryWidget(
                key: NotificationsKeys.error,
                message: vm.error!,
                onRetry: ref.read(notificationsViewModelProvider.notifier).load,
              ),
            if (!vm.isLoading && vm.error == null && vm.notifications.isEmpty)
              const EmptyStateWidget(
                key: NotificationsKeys.empty,
                message: 'Chưa có thông báo.',
                icon: Icons.notifications_none_rounded,
              ),
            ...vm.notifications.map(
              (n) => ListTile(
                key: NotificationsKeys.item(n.id),
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
                        key: NotificationsKeys.markRead(n.id),
                        onPressed: () => ref
                            .read(notificationsViewModelProvider.notifier)
                            .markOneAsRead(n.id),
                        child: const Text('Đánh dấu đã đọc'),
                      ),
              ),
            ),
            // A later page failed while earlier ones are shown.
            if (vm.error != null && vm.notifications.isNotEmpty)
              ErrorRetryWidget(
                message: vm.error!,
                onRetry: ref
                    .read(notificationsViewModelProvider.notifier)
                    .loadMore,
                compact: true,
              ),
            if (vm.isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: LoadingWidget(),
              ),
            if (!vm.isLoading && !vm.isLoadingMore && vm.hasMore)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: OutlinedButton(
                  key: NotificationsKeys.loadMore,
                  onPressed: ref
                      .read(notificationsViewModelProvider.notifier)
                      .loadMore,
                  child: const Text('Xem thêm'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
