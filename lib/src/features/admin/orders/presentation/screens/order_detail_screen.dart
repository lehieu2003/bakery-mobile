import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/core/utils/image_url.dart';
import 'package:bakery_mobile/src/features/admin/orders/domain/models/admin_order.dart';
import 'package:bakery_mobile/src/features/admin/orders/domain/models/order_audit.dart';
import 'package:bakery_mobile/src/features/admin/orders/domain/models/order_status_transitions.dart';
import 'package:bakery_mobile/src/features/admin/orders/presentation/controllers/order_detail_view_model.dart';
import 'package:bakery_mobile/src/features/admin/orders/presentation/widgets/audit_log_list.dart';
import 'package:bakery_mobile/src/features/admin/orders/presentation/widgets/invoice_pdf.dart';
import 'package:bakery_mobile/src/features/admin/shared/domain/order_status_display.dart';
import 'package:bakery_mobile/src/features/admin/shared/presentation/widgets/status_pill.dart';
import 'package:bakery_mobile/src/features/admin/shared/utils/admin_format.dart';

/// Max callback events / reconciliation attempts shown (web parity).
const int _investigationLimit = 10;

/// Admin order detail: customer, payment, items, totals, status transitions
/// (cancel requires a reason), audit trail, payment investigation and the
/// printable / shareable invoice.
class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderNumber});

  final String orderNumber;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  OrderDetailViewModel get _vm =>
      ref.read(orderDetailViewModelProvider(widget.orderNumber).notifier);

  @override
  void initState() {
    super.initState();
    Future.microtask(_vm.load);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _changeStatus(String next) async {
    String? notes;
    if (next == 'CANCELLED') {
      notes = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const _CancelReasonSheet(),
      );
      if (notes == null) return;
    }
    final ok = await _vm.updateStatus(next, notes: notes);
    if (!mounted) return;
    final state = ref.read(orderDetailViewModelProvider(widget.orderNumber));
    if (ok) {
      final updated = state.order;
      if (updated != null) {
        ref.read(ordersAdminViewModelProvider.notifier).replaceOrder(updated);
      }
      _snack('Đã chuyển sang "${orderStatusLabel(next)}"');
    } else if (state.updateError != null) {
      _snack(state.updateError!);
    }
  }

  Future<void> _openInvoiceMenu(AdminOrder order) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.print_outlined),
              title: const Text('In hoá đơn'),
              onTap: () => Navigator.pop(sheetContext, 'print'),
            ),
            ListTile(
              leading: const Icon(Icons.ios_share),
              title: const Text('Chia sẻ PDF'),
              onTap: () => Navigator.pop(sheetContext, 'share'),
            ),
          ],
        ),
      ),
    );
    if (action == null) return;
    try {
      if (action == 'print') {
        await Printing.layoutPdf(
          name: 'invoice_${order.orderNumber}',
          onLayout: (_) => buildInvoicePdf(order),
        );
      } else {
        final bytes = await buildInvoicePdf(order);
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/invoice_${order.orderNumber}.pdf');
        await file.writeAsBytes(bytes);
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path, mimeType: 'application/pdf')]),
        );
      }
    } catch (error) {
      if (mounted) _snack('Không thể tạo hoá đơn: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderDetailViewModelProvider(widget.orderNumber));
    final order = state.order;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.orderNumber),
        actions: [
          if (order != null)
            IconButton(
              tooltip: 'Hoá đơn',
              icon: const Icon(Icons.print),
              onPressed: () => _openInvoiceMenu(order),
            ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(OrderDetailState state) {
    final order = state.order;
    if (order == null) {
      if (state.error != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              TextButton(onPressed: _vm.load, child: const Text('Thử lại')),
            ],
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _vm.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _OrderHeader(order: order),
          const SizedBox(height: 12),
          _StatusSection(
            order: order,
            isUpdating: state.isUpdating,
            onSelect: _changeStatus,
          ),
          _CustomerCard(order: order),
          _PaymentCard(order: order),
          _ItemsCard(order: order),
          _TotalsCard(order: order),
          _SectionCard(
            title: 'Nhật ký',
            child: state.audit == null
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : AuditLogList(logs: state.audit!),
          ),
          _InvestigationCard(
            state: state,
            onExpand: () {
              if (state.investigation == null) _vm.loadInvestigation();
            },
            onRetry: _vm.loadInvestigation,
          ),
        ],
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.order});

  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.orderNumber,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppTheme.inkBrown,
                ),
              ),
              Text(
                'Tạo lúc ${formatDateTimeVi(order.createdAt.toLocal())}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.warmBrown,
                ),
              ),
            ],
          ),
        ),
        StatusPill(status: order.status),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.inkBrown,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

/// Label/value line used by the info cards.
class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.warmBrown,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({
    required this.order,
    required this.isUpdating,
    required this.onSelect,
  });

  final AdminOrder order;
  final bool isUpdating;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final next = nextStatuses(order.status);
    final Widget content;
    if (next.isEmpty) {
      content = Text(
        order.status == 'CANCELLED' ? 'Đơn đã huỷ' : 'Đơn đã hoàn tất',
        style: const TextStyle(color: AppTheme.warmBrown),
      );
    } else {
      content = Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final status in next)
            ActionChip(
              avatar: Icon(
                status == 'CANCELLED'
                    ? Icons.close
                    : Icons.arrow_forward_rounded,
                size: 18,
                color: orderStatusTextColor(status),
              ),
              label: Text(orderStatusLabel(status)),
              backgroundColor: orderStatusColor(status),
              labelStyle: TextStyle(
                color: orderStatusTextColor(status),
                fontWeight: FontWeight.w600,
              ),
              onPressed: isUpdating ? null : () => onSelect(status),
            ),
          if (isUpdating)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      );
    }
    return _SectionCard(title: 'Cập nhật trạng thái', child: content);
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.order});

  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    final email = order.customerEmail ?? order.user?.email;
    final address = order.customerAddress;
    final memberLevel = order.user?.memberLevel;
    return _SectionCard(
      title: 'Khách hàng',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.customerName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (memberLevel != null && memberLevel.isNotEmpty)
                Chip(
                  label: Text(memberLevel),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppTheme.blushPink,
                ),
            ],
          ),
          _InfoRow('Số điện thoại', order.customerPhone),
          if (email != null && email.isNotEmpty) _InfoRow('Email', email),
          if (address != null && address.isNotEmpty)
            _InfoRow('Địa chỉ', address),
          if (order.pickupDate != null)
            _InfoRow('Ngày nhận', formatDateVi(order.pickupDate!.toLocal())),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.order});

  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    final payment = order.payment;
    return _SectionCard(
      title: 'Thanh toán',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow('Phương thức', order.paymentMethod ?? 'Chưa chọn'),
          if (payment == null)
            const _InfoRow('Giao dịch', 'Chưa có')
          else ...[
            _InfoRow('Cổng', payment.provider),
            _InfoRow('Trạng thái', payment.status),
            _InfoRow('Số tiền', formatVnd(payment.amount)),
            if (payment.transactionId != null)
              _InfoRow('Mã giao dịch', payment.transactionId!),
          ],
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.order});

  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      title: 'Sản phẩm (${order.items.length})',
      child: Column(
        children: [
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Thumbnail(url: resolveImageUrl(item.imageUrl)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: theme.textTheme.bodyMedium),
                        if (item.message != null &&
                            item.message!.trim().isNotEmpty)
                          Text(
                            item.message!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: AppTheme.warmBrown,
                            ),
                          ),
                        Text(
                          '${item.quantity} × ${formatVnd(item.price)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.warmBrown,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatVnd(item.subtotal),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    const size = 48.0;
    final placeholder = Container(
      width: size,
      height: size,
      color: AppTheme.canvasCream,
      child: const Icon(Icons.cake_outlined, color: AppTheme.warmBrown),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: url.isEmpty
          ? placeholder
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.order});

  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget row(String label, String value, {bool strong = false}) {
      final style = strong
          ? theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.inkBrown,
            )
          : theme.textTheme.bodyMedium;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(label, style: style)),
            Text(value, style: style),
          ],
        ),
      );
    }

    return _SectionCard(
      title: 'Thanh toán đơn hàng',
      child: Column(
        children: [
          row('Tạm tính', formatVnd(order.subtotal)),
          if (order.deliveryFee > 0)
            row('Phí giao hàng', formatVnd(order.deliveryFee)),
          if (order.discount > 0)
            row('Giảm giá', '-${formatVnd(order.discount)}'),
          const Divider(),
          row('Tổng cộng', formatVnd(order.total), strong: true),
        ],
      ),
    );
  }
}

class _InvestigationCard extends StatelessWidget {
  const _InvestigationCard({
    required this.state,
    required this.onExpand,
    required this.onRetry,
  });

  final OrderDetailState state;
  final VoidCallback onExpand;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: const Text('Điều tra thanh toán'),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        onExpansionChanged: (expanded) {
          if (expanded) onExpand();
        },
        children: [_content(context)],
      ),
    );
  }

  Widget _content(BuildContext context) {
    if (state.isLoadingInvestigation) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.investigationError != null) {
      return Column(
        children: [
          Text(
            state.investigationError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      );
    }
    final data = state.investigation;
    if (data == null) return const SizedBox.shrink();

    final payment = data.payment;
    final events = data.callbackEvents.take(_investigationLimit).toList();
    final attempts = data.attempts.take(_investigationLimit).toList();
    final theme = Theme.of(context);
    final heading = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: AppTheme.warmBrown,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow('Trạng thái đơn', orderStatusLabel(data.orderStatus)),
        _InfoRow(
          'Thanh toán',
          payment == null
              ? 'Chưa có'
              : '${payment.provider} · ${payment.status} · '
                    '${formatVnd(payment.amount)}',
        ),
        const SizedBox(height: 8),
        Text('Callback (${data.callbackEvents.length})', style: heading),
        if (events.isEmpty) Text('Không có', style: muted),
        for (final event in events) _eventLine(event, theme, muted),
        const SizedBox(height: 8),
        Text('Đối soát (${data.attempts.length})', style: heading),
        if (attempts.isEmpty) Text('Không có', style: muted),
        for (final attempt in attempts)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(
              '${formatDateTimeVi(attempt.createdAt.toLocal())} · '
              '${attempt.provider} · ${attempt.outcome}'
              '${attempt.incomingStatus != null ? ' · ${attempt.incomingStatus}' : ''}',
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _eventLine(
    OrderCallbackEvent event,
    ThemeData theme,
    TextStyle? muted,
  ) {
    final result = [
      if (event.outcome != null) event.outcome!,
      if (event.reason != null) event.reason!,
    ].join(' — ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${event.provider} · ${event.event}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '${formatDateTimeVi(event.createdAt.toLocal())}'
            '${result.isNotEmpty ? ' · $result' : ''}',
            style: muted,
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet asking for the (mandatory) cancellation reason; pops with the
/// trimmed reason, or null when dismissed.
class _CancelReasonSheet extends StatefulWidget {
  const _CancelReasonSheet();

  @override
  State<_CancelReasonSheet> createState() => _CancelReasonSheetState();
}

class _CancelReasonSheetState extends State<_CancelReasonSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reason = _controller.text.trim();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Huỷ đơn hàng',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Lý do huỷ sẽ được lưu vào nhật ký đơn.',
            style: TextStyle(color: AppTheme.warmBrown),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 3,
            minLines: 2,
            decoration: const InputDecoration(hintText: 'Nhập lý do huỷ'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: reason.isEmpty
                ? null
                : () => Navigator.pop(context, reason),
            child: const Text('Xác nhận huỷ'),
          ),
        ],
      ),
    );
  }
}
