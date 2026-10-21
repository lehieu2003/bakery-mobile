import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/admin/orders/domain/models/admin_order.dart';
import 'package:bakery_mobile/src/features/admin/orders/presentation/controllers/orders_admin_view_model.dart';
import 'package:bakery_mobile/src/features/admin/orders/presentation/screens/order_detail_screen.dart';
import 'package:bakery_mobile/src/features/admin/orders/presentation/widgets/order_card.dart';
import 'package:bakery_mobile/src/features/admin/orders/utils/orders_csv.dart';
import 'package:bakery_mobile/src/shared/utils/order_status_display.dart';
import 'package:bakery_mobile/src/features/admin/shared/presentation/widgets/admin_paged_list.dart';
import 'package:bakery_mobile/src/core/theme/app_durations.dart';

/// Status filter chips: 'Tất cả' plus the 6 lifecycle statuses.
final List<AdminFilterChip> _statusFilters = [
  const AdminFilterChip(label: 'Tất cả', value: null),
  for (final status in const [
    'PENDING',
    'CONFIRMED',
    'PROCESSING',
    'READY',
    'COMPLETED',
    'CANCELLED',
  ])
    AdminFilterChip(label: orderStatusLabel(status), value: status),
];

/// Admin orders list (section "Đơn hàng"): search, status filter, infinite
/// scroll and CSV export of the loaded orders.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  /// Raw text of the search field. Kept here (not read back from the VM's
  /// trimmed, debounced `search`) so rebuilds never overwrite what the admin
  /// is still typing.
  String _searchText = '';
  Timer? _debounce;
  bool _exporting = false;

  OrdersAdminViewModel get _vm =>
      ref.read(ordersAdminViewModelProvider.notifier);

  @override
  void initState() {
    super.initState();
    _searchText = ref.read(ordersAdminViewModelProvider).search;
    Future.microtask(_vm.load);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchText = value);
    _debounce?.cancel();
    _debounce = Timer(AppDurations.searchDebounce, () => _vm.setSearch(value));
  }

  Future<void> _exportCsv(BuildContext buttonContext) async {
    final orders = ref.read(ordersAdminViewModelProvider).items;
    if (orders.isEmpty || _exporting) return;
    // iPad share sheets need an anchor rect; harmless elsewhere.
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    setState(() => _exporting = true);
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${ordersCsvFileName()}');
      await file.writeAsString(buildOrdersCsv(orders));
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          sharePositionOrigin: origin,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể xuất CSV: $error')));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _openOrder(AdminOrder order) {
    // Root navigator: the detail has its own AppBar and must cover the
    // AdminShell chrome (this screen lives in the shell's nested Navigator).
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailScreen(orderNumber: order.orderNumber),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersAdminViewModelProvider);

    // A failed refresh/load-more while orders are already on screen is not
    // rendered by AdminPagedList unless a next page exists (its footer) —
    // surface it as a snackbar instead.
    ref.listen<OrdersAdminState>(ordersAdminViewModelProvider, (prev, next) {
      final error = next.error;
      if (error == null || error == prev?.error) return;
      if (next.items.isEmpty || next.hasMore) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${state.total} đơn hàng',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.warmBrown),
                ),
              ),
              Builder(
                builder: (buttonContext) => IconButton(
                  key: const Key('orders_export_csv'),
                  tooltip: 'Xuất CSV',
                  icon: _exporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.file_download_outlined),
                  onPressed: state.items.isEmpty || _exporting
                      ? null
                      : () => _exportCsv(buttonContext),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: AdminPagedList<AdminOrder>(
            items: state.items,
            isLoading: state.isLoading,
            error: state.error,
            onRetry: _vm.retry,
            isLoadingMore: state.isLoadingMore,
            hasMore: state.hasMore,
            onLoadMore: _vm.loadMore,
            onRefresh: _vm.load,
            itemBuilder: (context, order) =>
                OrderCard(order: order, onTap: () => _openOrder(order)),
            searchHint: 'Tìm mã đơn, tên, số điện thoại',
            searchText: _searchText,
            onSearchChanged: _onSearchChanged,
            filters: _statusFilters,
            selectedFilter: state.statusFilter,
            onFilterSelected: _vm.setStatusFilter,
            emptyText: 'Chưa có đơn hàng',
          ),
        ),
      ],
    );
  }
}
