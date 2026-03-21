class OrderItem {
  const OrderItem({
    required this.name,
    required this.price,
    required this.quantity,
  });

  final String name;
  final double price;
  final int quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: (json['name'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      quantity: json['quantity'] is int
          ? json['quantity'] as int
          : int.tryParse('${json['quantity'] ?? ''}') ?? 0,
    );
  }
}

class Order {
  const Order({
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
  final List<OrderItem> orderItems;

  factory Order.fromJson(Map<String, dynamic> json) {
    final items = json['orderItems'] as List<dynamic>? ?? const [];
    return Order(
      id: (json['id'] ?? '').toString(),
      orderNumber: (json['orderNumber'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      total: (json['total'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
      orderItems: items
          .whereType<Map<String, dynamic>>()
          .map(OrderItem.fromJson)
          .toList(),
    );
  }
}

class CreateOrderResult {
  const CreateOrderResult({
    required this.order,
    this.paymentUrl,
    this.paymentError,
  });

  final Order order;
  final String? paymentUrl;
  final String? paymentError;

  factory CreateOrderResult.fromJson(Map<String, dynamic> json) {
    return CreateOrderResult(
      order: Order.fromJson((json['order'] as Map<String, dynamic>? ?? {})),
      paymentUrl: json['paymentUrl']?.toString(),
      paymentError: json['paymentError']?.toString(),
    );
  }
}

