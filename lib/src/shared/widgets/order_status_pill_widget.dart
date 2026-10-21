import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/shared/utils/order_status_display.dart';

/// Rounded pill showing the Vietnamese label of an order status, tinted with
/// the status background/text color pair.
class OrderStatusPillWidget extends StatelessWidget {
  const OrderStatusPillWidget({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: orderStatusColor(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        orderStatusLabel(status),
        style: TextStyle(
          color: orderStatusTextColor(status),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
