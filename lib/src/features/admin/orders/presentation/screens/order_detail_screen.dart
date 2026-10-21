import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/admin/orders/domain/models/admin_order.dart';
import 'package:bakery_mobile/src/features/admin/orders/domain/models/order_audit.dart';
import 'package:bakery_mobile/src/features/admin/orders/domain/models/order_status_transitions.dart';
import 'package:bakery_mobile/src/features/admin/orders/presentation/controllers/order_detail_view_model.dart';
import 'package:bakery_mobile/src/features/admin/orders/presentation/widgets/audit_log_list.dart';
import 'package:bakery_mobile/src/features/admin/orders/presentation/widgets/invoice_pdf.dart';
import 'package:bakery_mobile/src/shared/utils/order_status_display.dart';
import 'package:bakery_mobile/src/shared/widgets/order_status_pill_widget.dart';
import 'package:bakery_mobile/src/shared/utils/format_utils.dart';
import 'package:bakery_mobile/src/shared/widgets/loading_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/app_network_image_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/section_card_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/info_row_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/summary_row_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

/// Max callback events / reconciliation attempts shown (web parity).
const int _investigationLimit = 10;

/// Spacing between the stacked section cards.
const EdgeInsets _sectionMargin = EdgeInsets.only(bottom: AppSpacing.md);

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
        return ErrorRetryWidget(message: state.error!, onRetry: _vm.load);
      }
      return const LoadingWidget();
    }

    return RefreshIndicator(
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
          _OrderHeader(order: order),
          const Gap(AppSpacing.md),
          _StatusSection(
            order: order,
            isUpdating: state.isUpdating,
            onSelect: _changeStatus,
          ),
          _CustomerCard(order: order),
          _PaymentCard(order: order),
          _ItemsCard(order: order),
          _TotalsCard(order: order),
          SectionCardWidget(
            margin: _sectionMargin,

            title: 'Nhật ký',
            child: state.audit == null
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: LoadingWidget(),
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
        OrderStatusPillWidget(status: order.status),
      ],
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
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
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
    return SectionCardWidget(
      margin: _sectionMargin,
      title: 'Cập nhật trạng thái',
      child: content,
    );
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
    return SectionCardWidget(
      margin: _sectionMargin,

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
          InfoRowWidget(label: 'Số điện thoại', value: order.customerPhone),
          if (email != null && email.isNotEmpty)
            InfoRowWidget(label: 'Email', value: email),
          if (address != null && address.isNotEmpty)
            InfoRowWidget(label: 'Địa chỉ', value: address),
          if (order.pickupDate != null)
            InfoRowWidget(
              label: 'Ngày nhận',
              value: formatDateVi(order.pickupDate!.toLocal()),
            ),
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
    return SectionCardWidget(
      margin: _sectionMargin,

      title: 'Thanh toán',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRowWidget(
            label: 'Phương thức',
            value: order.paymentMethod ?? 'Chưa chọn',
          ),
          if (payment == null)
            const InfoRowWidget(label: 'Giao dịch', value: 'Chưa có')
          else ...[
            InfoRowWidget(label: 'Cổng', value: payment.provider),
            InfoRowWidget(label: 'Trạng thái', value: payment.status),
            InfoRowWidget(label: 'Số tiền', value: formatVnd(payment.amount)),
            if (payment.transactionId != null)
              InfoRowWidget(
                label: 'Mã giao dịch',
                value: payment.transactionId!,
              ),
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
    return SectionCardWidget(
      margin: _sectionMargin,

      title: 'Sản phẩm (${order.items.length})',
      child: Column(
        children: [
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppNetworkImageWidget(
                    url: item.imageUrl,
                    width: 48,
                    height: 48,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    backgroundColor: AppTheme.canvasCream,
                    emptyIcon: Icons.cake_outlined,
                    errorIcon: Icons.cake_outlined,
                    iconColor: AppTheme.warmBrown,
                  ),
                  const Gap(AppSpacing.md),
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

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.order});

  final AdminOrder order;

  @override
  Widget build(BuildContext context) {
    return SectionCardWidget(
      margin: _sectionMargin,

      title: 'Thanh toán đơn hàng',
      child: Column(
        children: [
          SummaryRowWidget(label: 'Tạm tính', value: formatVnd(order.subtotal)),
          if (order.deliveryFee > 0)
            SummaryRowWidget(
              label: 'Phí giao hàng',
              value: formatVnd(order.deliveryFee),
            ),
          if (order.discount > 0)
            SummaryRowWidget(
              label: 'Giảm giá',
              value: '-${formatVnd(order.discount)}',
            ),
          const Divider(),
          SummaryRowWidget(
            label: 'Tổng cộng',
            value: formatVnd(order.total),
            variant: SummaryRowVariant.total,
          ),
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
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: const Text('Điều tra thanh toán'),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
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
      return const LoadingWidget();
    }
    if (state.investigationError != null) {
      return ErrorRetryWidget(
        message: state.investigationError!,
        onRetry: onRetry,
        compact: true,
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
        InfoRowWidget(
          label: 'Trạng thái đơn',
          value: orderStatusLabel(data.orderStatus),
        ),
        InfoRowWidget(
          label: 'Thanh toán',
          value: payment == null
              ? 'Chưa có'
              : '${payment.provider} · ${payment.status} · '
                    '${formatVnd(payment.amount)}',
        ),
        const Gap(AppSpacing.sm),
        Text('Callback (${data.callbackEvents.length})', style: heading),
        if (events.isEmpty) Text('Không có', style: muted),
        for (final event in events) _eventLine(event, theme, muted),
        const Gap(AppSpacing.sm),
        Text('Đối soát (${data.attempts.length})', style: heading),
        if (attempts.isEmpty) Text('Không có', style: muted),
        for (final attempt in attempts)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
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
          const Gap(AppSpacing.xs),
          const Text(
            'Lý do huỷ sẽ được lưu vào nhật ký đơn.',
            style: TextStyle(color: AppTheme.warmBrown),
          ),
          const Gap(AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 3,
            minLines: 2,
            decoration: const InputDecoration(hintText: 'Nhập lý do huỷ'),
            onChanged: (_) => setState(() {}),
          ),
          const Gap(AppSpacing.md),
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
