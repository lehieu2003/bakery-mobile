import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/features/admin/content/notifications/domain/models/admin_notification.dart';
import 'package:bakery_mobile/src/features/admin/content/notifications/presentation/controllers/notifications_admin_view_model.dart';
import 'package:bakery_mobile/src/features/admin/content/notifications/presentation/widgets/notification_create_sheet.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';

/// Notifications admin: paged list, status chips, server-side search and a
/// create sheet (DRAFT by default).
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(notificationsAdminViewModelProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsAdminViewModelProvider);
    final vm = ref.read(notificationsAdminViewModelProvider.notifier);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm thông báo…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onSubmitted: vm.setSearch,
            ),
          ),
          const Gap(AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final (label, value) in [
                  ('Tất cả', null),
                  ('Bản nháp', 'DRAFT'),
                  ('Đã đăng', 'PUBLISHED'),
                  ('Lưu trữ', 'ARCHIVED'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: state.statusFilter == value,
                    onSelected: (_) => vm.setStatusFilter(value),
                  ),
              ],
            ),
          ),
          const Gap(AppSpacing.sm),
          Expanded(
            child: state.isLoading && state.items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.error != null && state.items.isEmpty
                ? ErrorRetryWidget(message: state.error!, onRetry: vm.load)
                : state.items.isEmpty
                ? Center(
                    child: Text(
                      'Chưa có thông báo nào',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: vm.load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: state.items.length,
                      separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                      itemBuilder: (context, index) =>
                          _NotificationCard(item: state.items[index]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showNotificationCreateSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Soạn thông báo'),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final AdminNotification item;

  String get _statusLabel {
    switch (item.status) {
      case NotificationStatus.published:
        return 'Đã đăng';
      case NotificationStatus.archived:
        return 'Lưu trữ';
      default:
        return 'Bản nháp';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(
                  _statusLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: item.status == NotificationStatus.published
                        ? Colors.green.shade700
                        : Colors.grey,
                  ),
                ),
              ],
            ),
            const Gap(4),
            Text(
              item.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
