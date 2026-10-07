import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/core/utils/image_url.dart';
import 'package:bakery_mobile/src/features/orders/domain/models/order.dart';

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
      return const Center(child: CircularProgressIndicator());
    }

    if (_notFound) {
      return _ErrorView(
        icon: Icons.search_off_outlined,
        title: 'Không tìm thấy đơn hàng',
        message:
            'Đơn hàng #${widget.orderNumber} không tồn tại hoặc không '
            'thuộc về tài khoản của bạn.',
        onRetry: _loadOrder,
        onBack: _goBack,
      );
    }

    if (_order == null) {
      return _ErrorView(
        icon: Icons.error_outline,
        title: 'Không thể tải đơn hàng',
        message: _errorMessage ?? 'Đã có lỗi xảy ra. Vui lòng thử lại.',
        onRetry: _loadOrder,
        onBack: _goBack,
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
                _OrderStatusBadge(status: order.status),
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
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 52,
            height: 52,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: imageUrl.isEmpty
                ? Icon(
                    Icons.bakery_dining_outlined,
                    size: 26,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )
                : Image.network(
                    imageUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.bakery_dining_outlined,
                      size: 26,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _SummaryRow(
              label: 'Tạm tính',
              value: _formatMoney(order.computedSubtotal),
            ),
            _SummaryRow(
              label: 'Giảm giá',
              value: order.discount > 0
                  ? '-${_formatMoney(order.discount)}'
                  : _formatMoney(0),
            ),
            _SummaryRow(
              label: 'Phí giao hàng',
              value: _formatMoney(order.deliveryFee),
            ),
            const Divider(height: 16),
            _SummaryRow(
              label: 'Tổng cộng',
              value: _formatMoney(order.total),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final textStyle = isTotal
        ? Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.primary,
          )
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textStyle),
          Text(value, style: textStyle),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thanh toán',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Phương thức',
              value: _paymentMethodLabel(order.paymentMethod),
            ),
            _InfoRow(
              label: 'Trạng thái',
              value: _paymentStatusLabel(
                order.paymentStatus,
                order.paymentMethod,
              ),
            ),
          ],
        ),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhận hàng',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (order.pickupDate != null)
              _InfoRow(
                label: 'Ngày nhận',
                value: _formatDate(order.pickupDate!),
              ),
            if (address.isNotEmpty) _InfoRow(label: 'Địa chỉ', value: address),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Mirrors the order status badge colors used by the Order History tiles in
/// the profile screen so the same status looks consistent in both places.
class _OrderStatusBadge extends StatelessWidget {
  const _OrderStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final colorScheme = Theme.of(context).colorScheme;
    Color bg = colorScheme.secondaryContainer;
    Color fg = colorScheme.onSecondaryContainer;

    if (normalized.contains('CANCEL')) {
      bg = colorScheme.errorContainer;
      fg = colorScheme.onErrorContainer;
    } else if (normalized.contains('PAID') || normalized.contains('SUCCESS')) {
      bg = Colors.green.withValues(alpha: 0.14);
      fg = Colors.green.shade800;
    } else if (normalized.contains('PENDING')) {
      bg = Colors.orange.withValues(alpha: 0.16);
      fg = Colors.orange.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _orderStatusLabel(status),
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }

  static String _orderStatusLabel(String status) {
    switch (status.trim().toUpperCase()) {
      case 'PENDING':
        return 'Chờ xác nhận';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'PROCESSING':
        return 'Đang chuẩn bị';
      case 'READY':
        return 'Sẵn sàng nhận';
      case 'COMPLETED':
        return 'Hoàn thành';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status;
    }
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: onBack, child: const Text('Quay lại')),
          ],
        ),
      ),
    );
  }
}

String _formatMoney(double value) {
  return '${value.toStringAsFixed(0)} VND';
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
