import 'package:bakery_mobile/src/features/admin/orders/domain/models/admin_order.dart';
import 'package:bakery_mobile/src/features/admin/shared/utils/json_num.dart';

/// Parses an admin order payload into the [AdminOrder] domain model. The
/// list rows and the detail response share the same shape, so a single
/// parser covers both; every field is read defensively (money may arrive
/// as numeric strings, `payment`/`user`/nullable fields may be absent).
class AdminOrderDto {
  const AdminOrderDto._();

  static AdminOrder fromJson(Map<String, dynamic> json) {
    final payment = json['payment'];
    final user = json['user'];
    return AdminOrder(
      id: (json['id'] ?? '').toString(),
      orderNumber: (json['orderNumber'] ?? '').toString(),
      userId: json['userId']?.toString(),
      customerName: (json['customerName'] ?? '').toString(),
      customerPhone: (json['customerPhone'] ?? '').toString(),
      customerEmail: json['customerEmail']?.toString(),
      customerAddress: json['customerAddress']?.toString(),
      pickupDate: json['pickupDate'] == null
          ? null
          : DateTime.tryParse('${json['pickupDate']}'),
      status: (json['status'] ?? '').toString(),
      subtotal: asNum(json['subtotal']).toDouble(),
      deliveryFee: asNum(json['deliveryFee']).toDouble(),
      discount: asNum(json['discount']).toDouble(),
      total: asNum(json['total']).toDouble(),
      paymentMethod: json['paymentMethod']?.toString(),
      createdAt:
          DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
      updatedAt:
          DateTime.tryParse('${json['updatedAt'] ?? ''}') ?? DateTime.now(),
      items: parseJsonList(
        json['orderItems'] ?? json['items'],
        _orderItemFromJson,
      ),
      payment: payment is Map<String, dynamic> ? _paymentFromJson(payment) : null,
      user: user is Map<String, dynamic> ? _userFromJson(user) : null,
    );
  }

  static AdminOrderItem _orderItemFromJson(Map<String, dynamic> json) {
    String? imageUrl;
    final product = json['product'];
    if (product is Map<String, dynamic>) {
      final images = product['images'];
      if (images is List<dynamic> && images.isNotEmpty) {
        final first = images.first;
        if (first is Map<String, dynamic> && first['url'] != null) {
          imageUrl = first['url'].toString();
        }
      }
    }

    return AdminOrderItem(
      id: (json['id'] ?? '').toString(),
      productId: json['productId']?.toString(),
      name: (json['name'] ?? '').toString(),
      message: json['message']?.toString(),
      price: asNum(json['price']).toDouble(),
      quantity: asNum(json['quantity']).toInt(),
      subtotal: asNum(json['subtotal']).toDouble(),
      imageUrl: imageUrl,
    );
  }

  static AdminPayment _paymentFromJson(Map<String, dynamic> json) {
    return AdminPayment(
      provider: (json['provider'] ?? '').toString(),
      transactionId: json['transactionId']?.toString(),
      amount: asNum(json['amount']).toDouble(),
      status: (json['status'] ?? '').toString(),
      createdAt:
          DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
    );
  }

  static AdminOrderUser _userFromJson(Map<String, dynamic> json) {
    return AdminOrderUser(
      id: (json['id'] ?? '').toString(),
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      memberLevel: json['memberLevel']?.toString(),
    );
  }
}

/// Envelope of `GET /api/admin/orders` (after `ApiClient` unwraps `data`):
/// `{ orders: [...], pagination: { page, limit, total, totalPages } }`.
class AdminOrderListDto {
  const AdminOrderListDto({required this.orders, required this.pagination});

  final List<AdminOrder> orders;
  final AdminOrderPaginationDto pagination;

  factory AdminOrderListDto.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'];
    return AdminOrderListDto(
      orders: parseJsonList(json['orders'], AdminOrderDto.fromJson),
      pagination: pagination is Map<String, dynamic>
          ? AdminOrderPaginationDto.fromJson(pagination)
          : const AdminOrderPaginationDto(),
    );
  }
}

/// `pagination` block of the admin orders list envelope.
class AdminOrderPaginationDto {
  const AdminOrderPaginationDto({
    this.page = 0,
    this.limit = 0,
    this.total = 0,
    this.totalPages = 0,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  factory AdminOrderPaginationDto.fromJson(Map<String, dynamic> json) {
    return AdminOrderPaginationDto(
      page: asNum(json['page']).toInt(),
      limit: asNum(json['limit']).toInt(),
      total: asNum(json['total']).toInt(),
      totalPages: asNum(json['totalPages']).toInt(),
    );
  }
}

/// Envelope of `PATCH /api/admin/orders/{id}` (after `ApiClient` unwraps
/// `data`): `{ order: {...} }` with the updated order.
class AdminOrderPatchResultDto {
  const AdminOrderPatchResultDto({required this.order});

  final AdminOrder order;

  factory AdminOrderPatchResultDto.fromJson(Map<String, dynamic> json) {
    final order = json['order'];
    return AdminOrderPatchResultDto(
      order: order is Map<String, dynamic>
          ? AdminOrderDto.fromJson(order)
          : AdminOrderDto.fromJson(const {}),
    );
  }
}
