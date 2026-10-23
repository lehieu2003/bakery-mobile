/// Admin view of an order as exposed by `GET /api/admin/orders` (list rows)
/// and `GET /api/admin/orders/{id|orderNumber}` (detail) — both share the
/// same shape. Money fields are doubles (server emits numeric strings);
/// optional fields are null when the server omits them.
class AdminOrder {
  const AdminOrder({
    required this.id,
    required this.orderNumber,
    this.userId,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    this.customerAddress,
    this.pickupDate,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    this.payment,
    this.user,
  });

  final String id;
  final String orderNumber;

  /// Account that placed the order; null for guest/legacy orders.
  final String? userId;
  final String customerName;
  final String customerPhone;

  /// Null for guest checkouts without email.
  final String? customerEmail;

  /// Null for pickup orders.
  final String? customerAddress;

  /// Preferred pickup day; null when the order is delivered.
  final DateTime? pickupDate;

  /// Lifecycle status, e.g. `PENDING` (uppercase, server enum).
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;

  /// e.g. `CASH`, `VNPAY`; null while unpaid.
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AdminOrderItem> items;

  /// Recorded payment, if one exists yet.
  final AdminPayment? payment;

  /// Cancelled after the customer paid: the money is still with the shop
  /// until it is refunded on the gateway portal and marked REFUNDED.
  bool get isAwaitingRefund =>
      status == 'CANCELLED' && payment?.status == 'PAID';

  /// Placing account; the list endpoint omits `email`, the detail includes it.
  final AdminOrderUser? user;
}

/// One line item of an [AdminOrder].
class AdminOrderItem {
  const AdminOrderItem({
    required this.id,
    this.productId,
    required this.name,
    this.message,
    required this.price,
    required this.quantity,
    required this.subtotal,
    this.imageUrl,
  });

  final String id;

  /// Product ordered; null when the product was removed from the catalog.
  final String? productId;
  final String name;

  /// Personalization note written by the customer (e.g. cake inscription).
  final String? message;
  final double price;
  final int quantity;
  final double subtotal;

  /// Primary product image (`product.images[0].url`); null when the product
  /// has no image.
  final String? imageUrl;
}

/// Payment recorded against an [AdminOrder].
class AdminPayment {
  const AdminPayment({
    required this.provider,
    this.transactionId,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  final String provider;

  /// Provider-side reference; null for offline payments.
  final String? transactionId;
  final double amount;
  final String status;
  final DateTime createdAt;
}

/// The account tied to an [AdminOrder]. The list endpoint returns
/// `{id, phone, name}` (no email); the detail endpoint adds `email` and
/// `memberLevel` — hence every field except [id] is nullable.
class AdminOrderUser {
  const AdminOrderUser({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.memberLevel,
  });

  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? memberLevel;
}
