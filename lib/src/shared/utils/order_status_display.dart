import 'package:flutter/material.dart';

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
  'PENDING': Color(0xFFFFF7E6),
  'CONFIRMED': Color(0xFFEFF6FF),
  'PROCESSING': Color(0xFFFFF7ED),
  'READY': Color(0xFFF0FDFA),
  'COMPLETED': Color(0xFFF0FDF4),
  'CANCELLED': Color(0xFFFEF2F2),
};

/// Pill text colors per order status code.
const Map<String, Color> _orderStatusTextColorMap = {
  'PENDING': Color(0xFFB45309),
  'CONFIRMED': Color(0xFF1D4ED8),
  'PROCESSING': Color(0xFFC2410C),
  'READY': Color(0xFF0F766E),
  'COMPLETED': Color(0xFF15803D),
  'CANCELLED': Color(0xFFB91C1C),
};

const Color _fallbackColor = Color(0xFFF3F4F6);
const Color _fallbackTextColor = Color(0xFF4B5563);

/// Human-readable Vietnamese label for an order [status] code; unknown codes
/// are returned unchanged.
String orderStatusLabel(String status) =>
    _orderStatusLabelMap[status.trim().toUpperCase()] ?? status;

/// Pill background color for an order [status] code.
Color orderStatusColor(String status) =>
    _orderStatusColorMap[status.trim().toUpperCase()] ?? _fallbackColor;

/// Pill text color for an order [status] code.
Color orderStatusTextColor(String status) =>
    _orderStatusTextColorMap[status.trim().toUpperCase()] ?? _fallbackTextColor;
