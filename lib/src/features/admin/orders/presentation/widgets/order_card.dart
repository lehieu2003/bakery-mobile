import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/admin/orders/domain/models/admin_order.dart';
import 'package:bakery_mobile/src/shared/widgets/order_status_pill_widget.dart';
import 'package:bakery_mobile/src/shared/utils/format_utils.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

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
      if (order.isAwaitingRefund)
        'CẦN HOÀN TIỀN'
      else if (order.payment != null)
        order.payment!.status,
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
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
              const Gap(AppSpacing.sm),
              Text(
                order.customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              const Gap(AppSpacing.sm),
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
              const Gap(AppSpacing.xs),
              Text(formatDateTimeVi(order.createdAt.toLocal()), style: muted),
            ],
          ),
        ),
      ),
    );
  }
}
