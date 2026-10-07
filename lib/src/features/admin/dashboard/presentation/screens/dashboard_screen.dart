import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/admin/dashboard/domain/models/dashboard_stats.dart';
import 'package:bakery_mobile/src/features/admin/dashboard/presentation/widgets/dashboard_charts.dart';
import 'package:bakery_mobile/src/features/admin/dashboard/presentation/widgets/kpi_card.dart';
import 'package:bakery_mobile/src/features/admin/shared/presentation/widgets/status_pill.dart';
import 'package:bakery_mobile/src/features/admin/shared/utils/admin_format.dart';

/// Admin dashboard: window switcher, 2×2 KPI grid, fl_chart trend charts and
/// the newest orders — driven by [dashboardViewModelProvider] (Task 5).
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // One post-frame kick-off: initial fetch plus the 5-minute polling loop.
    // startAutoRefresh() cancels any previous timer first, so calling it once
    // here keeps exactly one loop alive for this screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final viewModel = ref.read(dashboardViewModelProvider.notifier);
      viewModel.load();
      viewModel.startAutoRefresh();
    });
  }

  Future<void> _reload() =>
      ref.read(dashboardViewModelProvider.notifier).load();

  void _selectWindow(int windowDays) =>
      ref.read(dashboardViewModelProvider.notifier).setWindow(windowDays);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardViewModelProvider);
    final stats = state.stats;

    // Nothing loaded yet: spinner while the first fetch is in flight, error
    // view (with retry) when it failed.
    if (stats == null) {
      if (state.error != null && !state.isLoading) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 40,
                    color: AppTheme.warmBrown,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final kpi = stats.kpi;
    // Status summary rows — only statuses actually present (count > 0).
    final statusRows = stats.orderStates
        .where((orderState) => orderState.count > 0)
        .toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _reload,
        // SingleChildScrollView + Column (not a lazy ListView) so every
        // section is materialised regardless of viewport height — the widget
        // tests find 'Đơn mới nhất' below the fold without scrolling.
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 7, label: Text('7 ngày')),
                    ButtonSegment(value: 14, label: Text('14 ngày')),
                    ButtonSegment(value: 30, label: Text('30 ngày')),
                  ],
                  selected: {state.windowDays},
                  onSelectionChanged: (selection) =>
                      _selectWindow(selection.first),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: KpiCard(
                        label: 'Đơn hôm nay',
                        value: '${kpi.todayOrders}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: KpiCard(
                        label: 'Doanh thu hôm nay',
                        value: formatVnd(kpi.todayRevenue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: KpiCard(
                        label: 'Tỷ lệ chuyển đổi',
                        value: '${kpi.conversionRate.toStringAsFixed(1)}%',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: KpiCard(
                        label: 'Trạng thái đơn',
                        value: '',
                        child: statusRows.isEmpty
                            ? Text(
                                '—',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              )
                            : Column(
                                children: [
                                  for (final orderState in statusRows)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          StatusPill(status: orderState.status),
                                          const Spacer(),
                                          Text(
                                            '${orderState.count}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.inkBrown,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DashboardCharts(chartData: stats.chartData),
                const SizedBox(height: 16),
                _RecentOrdersCard(orders: stats.recentOrders.take(5).toList()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 'Đơn mới nhất' — the newest orders (max 5) with number, customer, item
/// count, total and status; rows are no-op tappable until phase 2.
class _RecentOrdersCard extends StatelessWidget {
  const _RecentOrdersCard({required this.orders});

  final List<DashboardRecentOrder> orders;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('dashboard_recent_orders'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Đơn mới nhất',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.inkBrown,
              ),
            ),
            const SizedBox(height: 8),
            if (orders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Chưa có đơn nào',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              for (final order in orders) _RecentOrderTile(order: order),
          ],
        ),
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  const _RecentOrderTile({required this.order});

  final DashboardRecentOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        // TODO(phase-2): push order detail
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          order.orderNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.inkBrown,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusPill(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.customerName} · ${order.itemsCount} món',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatVnd(order.total),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.inkBrown,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatDateVi(order.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
