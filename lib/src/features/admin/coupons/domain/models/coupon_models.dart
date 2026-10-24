/// Admin coupon row (`GET /api/admin/coupons`).
/// `value` is `PERCENTAGE` (0-100) or `FIXED` (₫) depending on [type].
class AdminCoupon {
  const AdminCoupon({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    required this.isActive,
    this.minOrder,
    this.maxDiscount,
    this.usageLimit,
    this.perUserLimit,
    this.startAt,
    this.endAt,
  });

  final String id;
  final String code;
  final String type;
  final double value;
  final double? minOrder;
  final double? maxDiscount;
  final int? usageLimit;
  final int? perUserLimit;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool isActive;
}
