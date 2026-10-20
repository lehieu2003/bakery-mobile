import 'package:intl/intl.dart';

import 'package:bakery_mobile/src/features/admin/orders/domain/models/admin_order.dart';

/// Header row — same 13 columns, same order as the web admin export.
const List<String> _ordersCsvHeaders = [
  'Order Number',
  'Customer Name',
  'Phone',
  'Email',
  'Address',
  'Subtotal',
  'Delivery Fee',
  'Discount',
  'Total',
  'Payment Method',
  'Payment Status',
  'Status',
  'Created At',
];

/// Builds the orders CSV (UTF-8 BOM first so Excel detects Vietnamese text).
/// Column values mirror the web export; unlike the web, cells are escaped
/// per RFC 4180 (quoted when they hold `,` `"` or a newline, `"` doubled).
String buildOrdersCsv(List<AdminOrder> orders) {
  final lines = <String>[
    _ordersCsvHeaders.map(_escape).join(','),
    for (final order in orders)
      [
        order.orderNumber,
        order.customerName,
        order.customerPhone,
        order.customerEmail ?? '',
        order.customerAddress ?? '',
        _money(order.subtotal),
        _money(order.deliveryFee),
        _money(order.discount),
        _money(order.total),
        order.paymentMethod ?? '',
        order.payment?.status ?? 'N/A',
        order.status,
        order.createdAt.toIso8601String(),
      ].map(_escape).join(','),
  ];
  return '﻿${lines.join('\n')}';
}

/// Export file name for [now] (defaults to today), e.g.
/// `orders_2026-10-07.csv`.
String ordersCsvFileName({DateTime? now}) =>
    'orders_${DateFormat('yyyy-MM-dd').format(now ?? DateTime.now())}.csv';

/// Compact number like JS `Number(x)`: `900000.0` → `900000`, `12.5` stays.
String _money(double value) =>
    value == value.truncateToDouble() ? value.toInt().toString() : '$value';

String _escape(String cell) {
  if (cell.contains(RegExp('[",\n\r]'))) {
    return '"${cell.replaceAll('"', '""')}"';
  }
  return cell;
}
