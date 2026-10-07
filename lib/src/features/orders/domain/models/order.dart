class OrderItem {
  const OrderItem({
    required this.name,
    required this.price,
    required this.quantity,
    this.subtotal = 0,
    this.imageUrl = '',
  });

  final String name;
  final double price;
  final int quantity;

  /// Line total as reported by the server (`orderItems[].subtotal`).
  final double subtotal;

  /// Primary product image URL as reported by the server (raw, may be
  /// relative — resolve with `resolveImageUrl` before displaying).
  final String imageUrl;

  double get lineTotal => subtotal > 0 ? subtotal : price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: (json['name'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      quantity: json['quantity'] is int
          ? json['quantity'] as int
          : int.tryParse('${json['quantity'] ?? ''}') ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      imageUrl: _extractPrimaryImageUrl(json['product']),
    );
  }

  static String _extractPrimaryImageUrl(dynamic product) {
    if (product is! Map<String, dynamic>) return '';
    final images = product['images'];
    if (images is! List<dynamic>) return '';

    String? firstUrl;
    for (final image in images) {
      if (image is! Map<String, dynamic>) continue;
      final url = (image['url'] ?? '').toString();
      if (url.isEmpty) continue;
      firstUrl ??= url;
      if (image['isPrimary'] == true) return url;
    }
    return firstUrl ?? '';
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
    this.subtotal = 0,
    this.deliveryFee = 0,
    this.discount = 0,
    this.paymentMethod = '',
    this.paymentStatus,
    this.pickupDate,
    this.customerName,
    this.customerAddress,
  });

  final String id;
  final String orderNumber;
  final String status;
  final double total;
  final DateTime createdAt;
  final List<OrderItem> orderItems;

  /// Order subtotal as reported by the server (`order.subtotal`).
  final double subtotal;

  /// Delivery fee as reported by the server (`order.deliveryFee`).
  final double deliveryFee;

  /// Total discount as reported by the server (`order.discount`).
  final double discount;

  /// Payment method code, e.g. `COD`, `BANK_TRANSFER`, `MOMO`, `VNPAY`.
  final String paymentMethod;

  /// Payment status, e.g. `PENDING`, `PAID`, `FAILED`; null when the order
  /// has no payment record yet.
  final String? paymentStatus;

  /// Requested pickup date; null when the server did not send one.
  final DateTime? pickupDate;

  final String? customerName;
  final String? customerAddress;

  /// Subtotal shown in the detail summary: prefers the server-reported value
  /// and falls back to the sum of the item line totals.
  double get computedSubtotal => subtotal > 0
      ? subtotal
      : orderItems.fold(0.0, (sum, item) => sum + item.lineTotal);

  factory Order.fromJson(Map<String, dynamic> json) {
    final items = json['orderItems'] as List<dynamic>? ?? const [];
    final payment = json['payment'];
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
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      paymentStatus: payment is Map<String, dynamic>
          ? payment['status']?.toString()
          : null,
      pickupDate: json['pickupDate'] == null
          ? null
          : DateTime.tryParse('${json['pickupDate']}'),
      customerName: json['customerName']?.toString(),
      customerAddress: json['customerAddress']?.toString(),
    );
  }
}

class CreateOrderResult {
  const CreateOrderResult({
    required this.order,
    this.paymentUrl,
    this.paymentError,
    this.appliedIncentives = const [],
  });

  final Order order;
  final String? paymentUrl;
  final String? paymentError;
  final List<AppliedIncentiveSummary> appliedIncentives;

  factory CreateOrderResult.fromJson(Map<String, dynamic> json) {
    return CreateOrderResult(
      order: Order.fromJson((json['order'] as Map<String, dynamic>? ?? {})),
      paymentUrl: json['paymentUrl']?.toString(),
      paymentError: json['paymentError']?.toString(),
      appliedIncentives:
          (json['appliedIncentives'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(AppliedIncentiveSummary.fromJson)
              .toList(),
    );
  }
}

class AppliedIncentiveSummary {
  const AppliedIncentiveSummary({
    required this.code,
    required this.type,
    required this.discount,
  });

  final String code;
  final String type;
  final double discount;

  factory AppliedIncentiveSummary.fromJson(Map<String, dynamic> json) {
    return AppliedIncentiveSummary(
      code: (json['code'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PreviewIncentiveResult {
  const PreviewIncentiveResult({
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
  final List<AppliedIncentiveSummary> appliedIncentives;
}

class AvailableIncentive {
  const AvailableIncentive({
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
}

class PrepareReorderResult {
  const PrepareReorderResult({
    required this.sourceOrderId,
    required this.sourceOrderNumber,
    this.items = const [],
    this.unavailableItems = const [],
  });

  final String sourceOrderId;
  final String sourceOrderNumber;
  final List<ReorderPreparedItem> items;
  final List<ReorderUnavailableItem> unavailableItems;
}

class ReorderPreparedItem {
  const ReorderPreparedItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.image,
    required this.type,
    this.variantId,
    this.variantName,
  });

  final String productId;
  final String? variantId;
  final String name;
  final String? variantName;
  final double price;
  final int quantity;
  final String image;
  final String type;
}

class ReorderUnavailableItem {
  const ReorderUnavailableItem({
    required this.productId,
    required this.name,
    required this.reason,
    required this.requestedQuantity,
    required this.availableQuantity,
    required this.guidance,
    this.variantId,
  });

  final String productId;
  final String? variantId;
  final String name;
  final String reason;
  final int requestedQuantity;
  final int availableQuantity;
  final String guidance;
}
