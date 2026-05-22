import 'package:bakery_mobile/src/features/orders/domain/models/order.dart';
import 'package:bakery_mobile/src/core/utils/parse_utils.dart';

class OrderItemDto {
  const OrderItemDto({
    required this.name,
    required this.price,
    required this.quantity,
  });

  final String name;
  final double price;
  final int quantity;

  factory OrderItemDto.fromJson(Map<String, dynamic> json) {
    return OrderItemDto(
      name: (json['name'] ?? '').toString(),
      price: ParseUtils.toDouble(json['price'], field: 'OrderItemDto.price'),
      quantity: ParseUtils.toInt(
        json['quantity'],
        field: 'OrderItemDto.quantity',
      ),
    );
  }

  OrderItem toDomain() =>
      OrderItem(name: name, price: price, quantity: quantity);
}

class OrderDto {
  const OrderDto({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.orderItems,
  });

  final String id;
  final String orderNumber;
  final String status;
  final double total;
  final DateTime createdAt;
  final List<OrderItemDto> orderItems;

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    final items = json['orderItems'] as List<dynamic>? ?? const [];
    return OrderDto(
      id: (json['id'] ?? '').toString(),
      orderNumber: (json['orderNumber'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      total: ParseUtils.toDouble(json['total'], field: 'OrderDto.total'),
      createdAt:
          DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
      orderItems: items
          .whereType<Map<String, dynamic>>()
          .map(OrderItemDto.fromJson)
          .toList(),
    );
  }

  Order toDomain() {
    return Order(
      id: id,
      orderNumber: orderNumber,
      status: status,
      total: total,
      createdAt: createdAt,
      orderItems: orderItems.map((e) => e.toDomain()).toList(),
    );
  }
}

class CreateOrderResultDto {
  const CreateOrderResultDto({
    required this.order,
    this.paymentUrl,
    this.paymentError,
    this.appliedIncentives = const [],
  });

  final OrderDto order;
  final String? paymentUrl;
  final String? paymentError;
  final List<AppliedIncentiveSummaryDto> appliedIncentives;

  factory CreateOrderResultDto.fromJson(Map<String, dynamic> json) {
    return CreateOrderResultDto(
      order: OrderDto.fromJson(
        json['order'] as Map<String, dynamic>? ?? const {},
      ),
      paymentUrl: json['paymentUrl']?.toString(),
      paymentError: json['paymentError']?.toString(),
      appliedIncentives:
          (json['appliedIncentives'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(AppliedIncentiveSummaryDto.fromJson)
              .toList(),
    );
  }

  CreateOrderResult toDomain() {
    return CreateOrderResult(
      order: order.toDomain(),
      paymentUrl: paymentUrl,
      paymentError: paymentError,
      appliedIncentives: appliedIncentives.map((e) => e.toDomain()).toList(),
    );
  }
}

class AppliedIncentiveSummaryDto {
  const AppliedIncentiveSummaryDto({
    required this.code,
    required this.type,
    required this.discount,
  });

  final String code;
  final String type;
  final double discount;

  factory AppliedIncentiveSummaryDto.fromJson(Map<String, dynamic> json) {
    return AppliedIncentiveSummaryDto(
      code: (json['code'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      discount: ParseUtils.toDouble(
        json['discount'],
        field: 'AppliedIncentiveSummaryDto.discount',
      ),
    );
  }

  AppliedIncentiveSummary toDomain() {
    return AppliedIncentiveSummary(code: code, type: type, discount: discount);
  }
}

class PreviewIncentiveResultDto {
  const PreviewIncentiveResultDto({
    required this.subtotal,
    required this.membershipDiscount,
    required this.couponDiscount,
    required this.totalDiscount,
    required this.total,
    this.appliedIncentives = const [],
  });

  final double subtotal;
  final double membershipDiscount;
  final double couponDiscount;
  final double totalDiscount;
  final double total;
  final List<AppliedIncentiveSummaryDto> appliedIncentives;

  factory PreviewIncentiveResultDto.fromJson(Map<String, dynamic> json) {
    return PreviewIncentiveResultDto(
      subtotal: ParseUtils.toDouble(
        json['subtotal'],
        field: 'PreviewIncentiveResultDto.subtotal',
      ),
      membershipDiscount: ParseUtils.toDouble(
        json['membershipDiscount'],
        field: 'PreviewIncentiveResultDto.membershipDiscount',
      ),
      couponDiscount: ParseUtils.toDouble(
        json['couponDiscount'],
        field: 'PreviewIncentiveResultDto.couponDiscount',
      ),
      totalDiscount: ParseUtils.toDouble(
        json['totalDiscount'],
        field: 'PreviewIncentiveResultDto.totalDiscount',
      ),
      total: ParseUtils.toDouble(
        json['total'],
        field: 'PreviewIncentiveResultDto.total',
      ),
      appliedIncentives:
          (json['appliedIncentives'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(AppliedIncentiveSummaryDto.fromJson)
              .toList(),
    );
  }

  PreviewIncentiveResult toDomain() {
    return PreviewIncentiveResult(
      subtotal: subtotal,
      membershipDiscount: membershipDiscount,
      couponDiscount: couponDiscount,
      totalDiscount: totalDiscount,
      total: total,
      appliedIncentives: appliedIncentives.map((e) => e.toDomain()).toList(),
    );
  }
}

class AvailableIncentiveDto {
  const AvailableIncentiveDto({
    required this.code,
    required this.type,
    required this.value,
    required this.endAt,
    this.minOrder,
    this.maxDiscount,
  });

  final String code;
  final String type;
  final double value;
  final double? minOrder;
  final double? maxDiscount;
  final DateTime endAt;

  factory AvailableIncentiveDto.fromJson(Map<String, dynamic> json) {
    return AvailableIncentiveDto(
      code: (json['code'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      value: ParseUtils.toDouble(
        json['value'],
        field: 'AvailableIncentiveDto.value',
      ),
      minOrder: json['minOrder'] == null
          ? null
          : ParseUtils.toDouble(
              json['minOrder'],
              field: 'AvailableIncentiveDto.minOrder',
            ),
      maxDiscount: json['maxDiscount'] == null
          ? null
          : ParseUtils.toDouble(
              json['maxDiscount'],
              field: 'AvailableIncentiveDto.maxDiscount',
            ),
      endAt: DateTime.tryParse('${json['endAt'] ?? ''}') ?? DateTime.now(),
    );
  }

  AvailableIncentive toDomain() {
    return AvailableIncentive(
      code: code,
      type: type,
      value: value,
      minOrder: minOrder,
      maxDiscount: maxDiscount,
      endAt: endAt,
    );
  }
}
