import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_radius.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/admin/customers/domain/models/admin_customer.dart';
import 'package:bakery_mobile/src/features/admin/customers/presentation/controllers/customer_detail_view_model.dart';
import 'package:bakery_mobile/src/features/admin/customers/presentation/widgets/member_level_badge.dart';
import 'package:bakery_mobile/src/shared/utils/format_utils.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/initial_avatar_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/loading_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/section_card_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/order_status_pill_widget.dart';

/// Spacing between the stacked section cards.
const EdgeInsets _sectionMargin = EdgeInsets.only(bottom: AppSpacing.md);

/// Admin customer detail (section "Khách hàng"): identity header, the 3
/// stat cards (orders / lifetime spend / points), and the recent orders,
/// payments and notifications with their read/unread summary. The 'Chỉnh
/// sửa' button opens the edit bottom sheet (Task 4).
class CustomerDetailScreen extends ConsumerStatefulWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final String customerId;

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  CustomerDetailViewModel get _vm =>
      ref.read(customerDetailViewModelProvider(widget.customerId).notifier);

  @override
  void initState() {
    super.initState();
    Future.microtask(_vm.load);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerDetailViewModelProvider(widget.customerId));
    final detail = state.detail;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết khách hàng')),
      body: detail == null
          ? state.error != null
                ? ErrorRetryWidget(message: state.error!, onRetry: _vm.retry)
                : const LoadingWidget()
          : RefreshIndicator(
              onRefresh: _vm.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.x3l,
                ),
                children: [
                  _HeaderCard(detail: detail, isSaving: state.isSaving),
                  const Gap(AppSpacing.md),
                  _StatsRow(detail: detail),
                  _RecentOrdersCard(orders: detail.recentOrders),
                  _RecentPaymentsCard(payments: detail.recentPayments),
                  _RecentNotificationsCard(
                    notifications: detail.recentNotifications,
                    summary: detail.notificationSummary,
                  ),
                ],
              ),
            ),
    );
  }
}

/// Identity block: avatar, name, email, member-tier badge, plus the phone /
/// joined date line and the 'Chỉnh sửa' button (Task 4 opens the sheet).
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.detail, required this.isSaving});

  final AdminCustomerDetail detail;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasName = detail.name?.trim().isNotEmpty ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InitialAvatarWidget(
                  name: hasName ? detail.name : detail.email,
                  radius: 24,
                  fallback: '?',
                ),
                const Gap(AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasName ? detail.name! : detail.email,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.inkBrown,
                        ),
                      ),
                      Text(
                        detail.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.warmBrown,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(AppSpacing.sm),
                MemberLevelBadge(level: detail.memberLevel),
              ],
            ),
            const Gap(AppSpacing.sm),
            if (detail.phone != null && detail.phone!.trim().isNotEmpty)
              Text(
                detail.phone!,
                style: theme.textTheme.bodyMedium,
              ),
            Text(
              'Tham gia từ ${formatDateVi(detail.createdAt.toLocal())}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.warmBrown,
              ),
            ),
            const Gap(AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                // Task 4 opens the member-level/points bottom sheet here.
                onPressed: isSaving ? null : () {},
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Chỉnh sửa'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One of the three stat tiles (Tổng đơn / Tổng chi / Điểm).
class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppTheme.canvasCream,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppTheme.blushPink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.inkBrown,
              ),
            ),
          ),
          const Gap(AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.warmBrown,
            ),
          ),
        ],
      ),
    );
  }
}

/// The three stat tiles: order count, lifetime spend and loyalty points.
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.detail});

  final AdminCustomerDetail detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(label: 'Tổng đơn', value: '${detail.totalOrders}'),
          ),
          const Gap(AppSpacing.sm),
          Expanded(
            child: _StatCard(
              label: 'Tổng chi',
              value: formatVnd(detail.totalSpent),
            ),
          ),
          const Gap(AppSpacing.sm),
          Expanded(
            child: _StatCard(label: 'Điểm', value: '${detail.points}'),
          ),
        ],
      ),
    );
  }
}

/// Recent orders (≤10, newest first): order number + total, status pill and
/// the placed date.
class _RecentOrdersCard extends StatelessWidget {
  const _RecentOrdersCard({required this.orders});

  final List<AdminCustomerOrder> orders;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCardWidget(
      margin: _sectionMargin,
      title: 'Đơn gần đây',
      child: orders.isEmpty
          ? const Text('Không có', style: TextStyle(color: AppTheme.warmBrown))
          : Column(
              children: [
                for (final (index, order) in orders.indexed) ...[
                  if (index > 0) const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.orderNumber,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        formatVnd(order.total),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Gap(AppSpacing.xs),
                  Row(
                    children: [
                      OrderStatusPillWidget(status: order.status),
                      const Spacer(),
                      Text(
                        formatDateVi(order.createdAt.toLocal()),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.warmBrown,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

/// Recent payments: provider + order, amount, transaction id and status.
class _RecentPaymentsCard extends StatelessWidget {
  const _RecentPaymentsCard({required this.payments});

  final List<AdminCustomerPayment> payments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCardWidget(
      margin: _sectionMargin,
      title: 'Thanh toán gần đây',
      child: payments.isEmpty
          ? const Text('Không có', style: TextStyle(color: AppTheme.warmBrown))
          : Column(
              children: [
                for (final (index, payment) in payments.indexed) ...[
                  if (index > 0) const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${payment.provider} · ${payment.orderNumber}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        formatVnd(payment.amount),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Gap(AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      [
                        if (payment.transactionId != null)
                          'GD ${payment.transactionId}',
                        payment.status,
                        formatDateVi(payment.createdAt.toLocal()),
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.warmBrown,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

/// Recent notification reads: title with a Đã đọc/Chưa đọc marker and the
/// publish date, closed by the 'X đã đọc · Y chưa đọc' summary line.
class _RecentNotificationsCard extends StatelessWidget {
  const _RecentNotificationsCard({
    required this.notifications,
    required this.summary,
  });

  final List<AdminCustomerNotification> notifications;
  final AdminNotificationSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCardWidget(
      margin: _sectionMargin,
      title: 'Thông báo gần đây',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notifications.isEmpty)
            const Text(
              'Không có',
              style: TextStyle(color: AppTheme.warmBrown),
            )
          else
            for (final (index, notification) in notifications.indexed) ...[
              if (index > 0) const Divider(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      notification.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    notification.readAt == null ? 'Chưa đọc' : 'Đã đọc',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: notification.readAt == null
                          ? AppTheme.inkBrown
                          : AppTheme.warmBrown,
                      fontWeight: notification.readAt == null
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const Gap(AppSpacing.xs),
              Text(
                formatDateVi(
                  (notification.publishedAt ?? notification.createdAt)
                      .toLocal(),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.warmBrown,
                ),
              ),
            ],
          if (notifications.isNotEmpty) ...[
            const Gap(AppSpacing.sm),
            Text(
              '${summary.totalRead} đã đọc · ${summary.unreadPublished} chưa đọc',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.warmBrown,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
