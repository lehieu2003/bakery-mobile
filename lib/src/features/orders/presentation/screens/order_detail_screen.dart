import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/core/utils/image_url.dart';
import 'package:bakery_mobile/src/features/orders/domain/models/order.dart';
import 'package:bakery_mobile/src/shared/widgets/loading_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/app_network_image_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/order_status_pill_widget.dart';
import 'package:bakery_mobile/src/shared/utils/format_utils.dart';
import 'package:bakery_mobile/src/shared/widgets/section_card_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/info_row_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/summary_row_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderNumber});

  final String orderNumber;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  Order? _order;
  bool _isLoading = true;
  bool _notFound = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _notFound = false;
      _errorMessage = null;
    });

    try {
      final order = await ref
          .read(orderRepositoryProvider)
          .getOrder(widget.orderNumber);
      if (!mounted) return;
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _notFound = error.statusCode == 404;
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const LoadingWidget();
    }

    if (_notFound) {
      return ErrorRetryWidget(
        icon: Icons.search_off_outlined,
        title: 'Không tìm thấy đơn hàng',
        message:
            'Đơn hàng #${widget.orderNumber} không tồn tại hoặc không '
            'thuộc về tài khoản của bạn.',
        onRetry: _loadOrder,
        secondaryAction: OutlinedButton(
          onPressed: _goBack,
          child: const Text('Quay lại'),
        ),
      );
    }

    if (_order == null) {
      return ErrorRetryWidget(
        icon: Icons.error_outline,
        title: 'Không thể tải đơn hàng',
        message: _errorMessage ?? 'Đã có lỗi xảy ra. Vui lòng thử lại.',
        onRetry: _loadOrder,
        secondaryAction: OutlinedButton(
          onPressed: _goBack,
          child: const Text('Quay lại'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrder,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _OrderHeaderCard(order: _order!),
          const SizedBox(height: 12),
          _OrderItemsCard(items: _order!.orderItems),
          const SizedBox(height: 12),
          _OrderSummaryCard(order: _order!),
          const SizedBox(height: 12),
          _OrderPaymentCard(order: _order!),
          if (_hasPickupInfo) ...[
            const SizedBox(height: 12),
            _OrderPickupCard(order: _order!),
          ],
        ],
      ),
    );
  }

  bool get _hasPickupInfo =>
      _order?.pickupDate != null ||
      (_order?.customerAddress?.trim().isNotEmpty ?? false);
}

class _OrderHeaderCard extends StatelessWidget {
  const _OrderHeaderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Đơn hàng #${order.orderNumber}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                OrderStatusPillWidget(status: order.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Ngày đặt: ${_formatDate(order.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderItemsCard extends StatelessWidget {
  const _OrderItemsCard({required this.items});

  final List<OrderItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sản phẩm',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OrderItemRow(item: item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveImageUrl(item.imageUrl);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppNetworkImageWidget(
          url: imageUrl,
          width: 52,
          height: 52,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          emptyIcon: Icons.bakery_dining_outlined,
          errorIcon: Icons.bakery_dining_outlined,
          iconSize: 26,
          iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.quantity} x ${_formatMoney(item.price)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          _formatMoney(item.lineTotal),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return SectionCardWidget(
      child: Column(
        children: [
          SummaryRowWidget(
            label: 'Tạm tính',
            value: _formatMoney(order.computedSubtotal),
          ),
          SummaryRowWidget(
            label: 'Giảm giá',
            value: order.discount > 0
                ? '-${_formatMoney(order.discount)}'
                : _formatMoney(0),
          ),
          SummaryRowWidget(
            label: 'Phí giao hàng',
            value: _formatMoney(order.deliveryFee),
          ),
          const Divider(height: 16),
          SummaryRowWidget(
            label: 'Tổng cộng',
            value: _formatMoney(order.total),
            variant: SummaryRowVariant.total,
            valueColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _OrderPaymentCard extends StatelessWidget {
  const _OrderPaymentCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return SectionCardWidget(
      title: 'Thanh toán',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoRowWidget(
            label: 'Phương thức',
            value: _paymentMethodLabel(order.paymentMethod),
          ),
          InfoRowWidget(
            label: 'Trạng thái',
            value: _paymentStatusLabel(
              order.paymentStatus,
              order.paymentMethod,
            ),
          ),
        ],
      ),
    );
  }

  static String _paymentMethodLabel(String method) {
    switch (method.trim().toUpperCase()) {
      case 'COD':
        return 'COD (Thanh toán khi nhận hàng)';
      case 'BANK_TRANSFER':
        return 'Chuyển khoản ngân hàng';
      case 'MOMO':
        return 'Ví MoMo';
      case 'ZALOPAY':
        return 'Ví ZaloPay';
      case 'VNPAY':
        return 'VNPAY';
      default:
        return method;
    }
  }

  static String _paymentStatusLabel(String? status, String method) {
    if (status == null || status.trim().isEmpty) {
      return method.trim().toUpperCase() == 'COD'
          ? 'Thanh toán khi nhận hàng'
          : 'Chưa có thông tin thanh toán';
    }
    switch (status.trim().toUpperCase()) {
      case 'PAID':
        return 'Đã thanh toán';
      case 'PENDING':
        return 'Chờ thanh toán';
      case 'FAILED':
        return 'Thanh toán thất bại';
      default:
        return status;
    }
  }
}

class _OrderPickupCard extends StatelessWidget {
  const _OrderPickupCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final address = order.customerAddress?.trim() ?? '';

    return SectionCardWidget(
      title: 'Nhận hàng',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (order.pickupDate != null)
            InfoRowWidget(
              label: 'Ngày nhận',
              value: _formatDate(order.pickupDate!),
            ),
          if (address.isNotEmpty)
            InfoRowWidget(label: 'Địa chỉ', value: address),
        ],
      ),
    );
  }
}

String _formatMoney(double value) {
  return formatVnd(value);
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
