import 'package:bakery_mobile/src/features/orders/domain/models/order.dart';

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
      price: (json['price'] as num?)?.toDouble() ?? 0,
      quantity: json['quantity'] is int
          ? json['quantity'] as int
          : int.tryParse('${json['quantity'] ?? ''}') ?? 0,
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
      total: (json['total'] as num?)?.toDouble() ?? 0,
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
  });

  final OrderDto order;
  final String? paymentUrl;
  final String? paymentError;

  factory CreateOrderResultDto.fromJson(Map<String, dynamic> json) {
    return CreateOrderResultDto(
      order: OrderDto.fromJson(
        json['order'] as Map<String, dynamic>? ?? const {},
      ),
      paymentUrl: json['paymentUrl']?.toString(),
      paymentError: json['paymentError']?.toString(),
    );
  }

  CreateOrderResult toDomain() {
    return CreateOrderResult(
      order: order.toDomain(),
      paymentUrl: paymentUrl,
      paymentError: paymentError,
    );
  }
}
