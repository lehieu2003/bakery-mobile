import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/admin/orders/domain/models/admin_order.dart';
import 'package:bakery_mobile/src/shared/widgets/order_status_pill_widget.dart';
import 'package:bakery_mobile/src/shared/utils/format_utils.dart';

/// One row of the admin orders list: order number + status, customer,
/// total, payment method/status and creation time.
class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, this.onTap});

  final AdminOrder order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: AppTheme.warmBrown,
    );
    final payment = [
      order.paymentMethod ?? 'Chưa chọn',
      if (order.payment != null) order.payment!.status,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.orderNumber,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.inkBrown,
                      ),
                    ),
                  ),
                  OrderStatusPillWidget(status: order.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                order.customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      payment,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                  ),
                  Text(
                    formatVnd(order.total),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.inkBrown,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(formatDateTimeVi(order.createdAt.toLocal()), style: muted),
            ],
          ),
        ),
      ),
    );
  }
}
