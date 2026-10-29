import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';

/// Vietnamese labels for order status codes (matched case-insensitively);
/// unknown codes fall back to the raw code via [orderStatusLabel].
const Map<String, String> _orderStatusLabelMap = {
  'PENDING': 'Chờ xác nhận',
  'CONFIRMED': 'Đã xác nhận',
  'PROCESSING': 'Đang chuẩn bị',
  'READY': 'Sẵn sàng nhận',
  'COMPLETED': 'Hoàn thành',
  'CANCELLED': 'Đã huỷ',
};

/// Pill background colors per order status code.
const Map<String, Color> _orderStatusColorMap = {
  'PENDING': AppTheme.statusPendingBg,
  'CONFIRMED': AppTheme.statusConfirmedBg,
  'PROCESSING': AppTheme.statusProcessingBg,
  'READY': AppTheme.statusReadyBg,
  'COMPLETED': AppTheme.statusCompletedBg,
  'CANCELLED': AppTheme.statusCancelledBg,
};

/// Pill text colors per order status code.
const Map<String, Color> _orderStatusTextColorMap = {
  'PENDING': AppTheme.statusPendingText,
  'CONFIRMED': AppTheme.statusConfirmedText,
  'PROCESSING': AppTheme.statusProcessingText,
  'READY': AppTheme.statusReadyText,
  'COMPLETED': AppTheme.statusCompletedText,
  'CANCELLED': AppTheme.statusCancelledText,
};

/// Human-readable Vietnamese label for an order [status] code; unknown codes
/// are returned unchanged.
String orderStatusLabel(String status) =>
    _orderStatusLabelMap[status.trim().toUpperCase()] ?? status;

/// Pill background color for an order [status] code.
Color orderStatusColor(String status) =>
    _orderStatusColorMap[status.trim().toUpperCase()] ??
    AppTheme.statusFallbackBg;

/// Pill text color for an order [status] code.
Color orderStatusTextColor(String status) =>
    _orderStatusTextColorMap[status.trim().toUpperCase()] ??
    AppTheme.statusFallbackText;

/// The steps an order moves through, in order, for the progress bar:
/// status code → short label.
const List<({String status, String label})> orderProgressSteps = [
  (status: 'PENDING', label: 'Đã đặt'),
  (status: 'CONFIRMED', label: 'Xác nhận'),
  (status: 'PROCESSING', label: 'Chuẩn bị'),
  (status: 'READY', label: 'Sẵn sàng'),
  (status: 'COMPLETED', label: 'Hoàn thành'),
];

/// Index of [status] in [orderProgressSteps]: every step up to it is done.
/// -1 for a cancelled or unknown status, which has no place on the bar.
int orderProgressIndex(String status) {
  final code = status.trim().toUpperCase();
  return orderProgressSteps.indexWhere((step) => step.status == code);
}
