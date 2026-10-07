import 'package:bakery_mobile/src/features/orders/domain/models/order.dart';
import 'package:bakery_mobile/src/core/utils/parse_utils.dart';

class OrderItemDto {
  const OrderItemDto({
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

  /// Primary product image URL (`product.images[].url`), raw and possibly
  /// relative; resolve with `resolveImageUrl` before displaying.
  final String imageUrl;

  factory OrderItemDto.fromJson(Map<String, dynamic> json) {
    return OrderItemDto(
      name: (json['name'] ?? '').toString(),
      price: ParseUtils.toDouble(json['price'], field: 'OrderItemDto.price'),
      quantity: ParseUtils.toInt(
        json['quantity'],
        field: 'OrderItemDto.quantity',
      ),
      subtotal: ParseUtils.toDouble(
        json['subtotal'],
        field: 'OrderItemDto.subtotal',
      ),
      imageUrl: _extractPrimaryImageUrl(json['product']),
    );
  }

  /// Picks the primary product image, falling back to the first non-empty
  /// one; tolerates a missing/null product or missing images.
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

  OrderItem toDomain() => OrderItem(
    name: name,
    price: price,
    quantity: quantity,
    subtotal: subtotal,
    imageUrl: imageUrl,
  );
}

class OrderDto {
  const OrderDto({
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
  final List<OrderItemDto> orderItems;

  /// Order subtotal as reported by the web `serializeOrder` payload.
  final double subtotal;

  /// Delivery fee as reported by the web `serializeOrder` payload.
  final double deliveryFee;

  /// Total discount as reported by the web `serializeOrder` payload.
  final double discount;

  /// Payment method code, e.g. `COD`, `BANK_TRANSFER`, `MOMO`, `VNPAY`.
  final String paymentMethod;

  /// Payment status (`payment.status`), null when `payment` is absent/null.
  final String? paymentStatus;

  /// Requested pickup date; null when missing or unparseable.
  final DateTime? pickupDate;

  final String? customerName;
  final String? customerAddress;

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    final items = json['orderItems'] as List<dynamic>? ?? const [];
    final payment = json['payment'];
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
      subtotal: ParseUtils.toDouble(
        json['subtotal'],
        field: 'OrderDto.subtotal',
      ),
      deliveryFee: ParseUtils.toDouble(
        json['deliveryFee'],
        field: 'OrderDto.deliveryFee',
      ),
      discount: ParseUtils.toDouble(
        json['discount'],
        field: 'OrderDto.discount',
      ),
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

  Order toDomain() {
    return Order(
      id: id,
      orderNumber: orderNumber,
      status: status,
      total: total,
      createdAt: createdAt,
      orderItems: orderItems.map((e) => e.toDomain()).toList(),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      pickupDate: pickupDate,
      customerName: customerName,
      customerAddress: customerAddress,
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

class PrepareReorderResultDto {
  const PrepareReorderResultDto({
    required this.sourceOrderId,
    required this.sourceOrderNumber,
    this.items = const [],
    this.unavailableItems = const [],
  });

  final String sourceOrderId;
  final String sourceOrderNumber;
  final List<ReorderPreparedItemDto> items;
  final List<ReorderUnavailableItemDto> unavailableItems;

  factory PrepareReorderResultDto.fromJson(Map<String, dynamic> json) {
    return PrepareReorderResultDto(
      sourceOrderId: (json['sourceOrderId'] ?? '').toString(),
      sourceOrderNumber: (json['sourceOrderNumber'] ?? '').toString(),
      items: (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ReorderPreparedItemDto.fromJson)
          .toList(),
      unavailableItems: (json['unavailableItems'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ReorderUnavailableItemDto.fromJson)
          .toList(),
    );
  }

  PrepareReorderResult toDomain() {
    return PrepareReorderResult(
      sourceOrderId: sourceOrderId,
      sourceOrderNumber: sourceOrderNumber,
      items: items.map((e) => e.toDomain()).toList(),
      unavailableItems: unavailableItems.map((e) => e.toDomain()).toList(),
    );
  }
}

class ReorderPreparedItemDto {
  const ReorderPreparedItemDto({
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

  factory ReorderPreparedItemDto.fromJson(Map<String, dynamic> json) {
    return ReorderPreparedItemDto(
      productId: (json['productId'] ?? '').toString(),
      variantId: json['variantId']?.toString(),
      name: (json['name'] ?? '').toString(),
      variantName: json['variantName']?.toString(),
      price: ParseUtils.toDouble(
        json['price'],
        field: 'ReorderPreparedItemDto.price',
      ),
      quantity: ParseUtils.toInt(
        json['quantity'],
        field: 'ReorderPreparedItemDto.quantity',
      ),
      image: (json['image'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
    );
  }

  ReorderPreparedItem toDomain() {
    return ReorderPreparedItem(
      productId: productId,
      variantId: variantId,
      name: name,
      variantName: variantName,
      price: price,
      quantity: quantity,
      image: image,
      type: type,
    );
  }
}

class ReorderUnavailableItemDto {
  const ReorderUnavailableItemDto({
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

  factory ReorderUnavailableItemDto.fromJson(Map<String, dynamic> json) {
    return ReorderUnavailableItemDto(
      productId: (json['productId'] ?? '').toString(),
      variantId: json['variantId']?.toString(),
      name: (json['name'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      requestedQuantity: ParseUtils.toInt(
        json['requestedQuantity'],
        field: 'ReorderUnavailableItemDto.requestedQuantity',
      ),
      availableQuantity: ParseUtils.toInt(
        json['availableQuantity'],
        field: 'ReorderUnavailableItemDto.availableQuantity',
      ),
      guidance: (json['guidance'] ?? '').toString(),
    );
  }

  ReorderUnavailableItem toDomain() {
    return ReorderUnavailableItem(
      productId: productId,
      variantId: variantId,
      name: name,
      reason: reason,
      requestedQuantity: requestedQuantity,
      availableQuantity: availableQuantity,
      guidance: guidance,
    );
  }
}
