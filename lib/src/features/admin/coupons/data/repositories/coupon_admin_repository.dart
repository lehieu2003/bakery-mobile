import 'package:bakery_mobile/src/features/admin/coupons/domain/models/coupon_models.dart';
import 'package:bakery_mobile/src/features/admin/coupons/data/datasources/coupon_admin_api_service.dart';

/// Parses a coupon row — `value` is a Decimal string ("20") → double.
AdminCoupon couponFromJson(Map<String, dynamic> json) => AdminCoupon(
  id: (json['id'] ?? '').toString(),
  code: (json['code'] ?? '').toString(),
  type: (json['type'] ?? 'PERCENTAGE').toString(),
  value: asNumCoupon(json['value']),
  minOrder: json['minOrder'] == null ? null : asNumCoupon(json['minOrder']),
  maxDiscount: json['maxDiscount'] == null
      ? null
      : asNumCoupon(json['maxDiscount']),
  usageLimit: json['usageLimit'] is num
      ? (json['usageLimit'] as num).toInt()
      : null,
  perUserLimit: json['perUserLimit'] is num
      ? (json['perUserLimit'] as num).toInt()
      : null,
  startAt: json['startAt'] == null
      ? null
      : DateTime.tryParse('${json['startAt']}'),
  endAt: json['endAt'] == null ? null : DateTime.tryParse('${json['endAt']}'),
  isActive: json['isActive'] == true,
);

double asNumCoupon(dynamic raw) =>
    raw is num ? raw.toDouble() : (double.tryParse('$raw') ?? 0);

class CouponAdminRepository {
  const CouponAdminRepository(this._service);

  final CouponAdminApiService _service;

  Future<List<AdminCoupon>> getCoupons() async {
    final data = await _service.getCoupons();
    final rows = data is Map<String, dynamic> ? data['coupons'] : data;
    if (rows is! List<dynamic>) return const [];
    return [
      for (final row in rows)
        if (row is Map<String, dynamic>) couponFromJson(row),
    ];
  }

  Future<void> createCoupon(Map<String, dynamic> body) =>
      _service.createCoupon(body);

  Future<void> deleteCoupon(String id) => _service.deleteCoupon(id);

  Future<void> setCouponActive(String id, {required bool isActive}) =>
      _service.updateCoupon(id, {'isActive': isActive});
}
