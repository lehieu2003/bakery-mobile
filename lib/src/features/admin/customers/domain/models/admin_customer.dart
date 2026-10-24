/// Admin view of a customer as exposed by `GET /api/admin/customers` (list
/// rows). Money fields are doubles (the server may emit numeric strings);
/// `name`/`phone` are null when the customer never filled them in.
class AdminCustomer {
  const AdminCustomer({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    required this.memberLevel,
    required this.points,
    required this.isActive,
    required this.createdAt,
    required this.totalOrders,
    required this.totalSpent,
  });

  final String id;

  /// Login identity; every customer account has one.
  final String email;

  /// Null when the customer never set a display name.
  final String? name;

  /// Null when the customer never added a phone number.
  final String? phone;

  /// Loyalty tier, e.g. `GOLD` (uppercase, server enum — [AdminMemberLevel]).
  final String memberLevel;
  final int points;
  final bool isActive;
  final DateTime createdAt;

  /// Number of orders ever placed (cancelled ones included).
  final int totalOrders;

  /// Sum of non-cancelled order totals.
  final double totalSpent;
}

/// Admin view of a customer with the detail-only blocks returned by
/// `GET /api/admin/customers/{id}` and `PATCH /api/admin/customers/{id}`.
class AdminCustomerDetail extends AdminCustomer {
  const AdminCustomerDetail({
    required super.id,
    required super.email,
    super.name,
    super.phone,
    required super.memberLevel,
    required super.points,
    required super.isActive,
    required super.createdAt,
    required super.totalOrders,
    required super.totalSpent,
    this.recentOrders = const [],
    this.recentPayments = const [],
    this.recentNotifications = const [],
    this.notificationSummary = const AdminNotificationSummary(),
  });

  /// The customer's 10 most recent orders (newest first).
  final List<AdminCustomerOrder> recentOrders;

  /// Payments extracted from [recentOrders] (flattened with their order).
  final List<AdminCustomerPayment> recentPayments;

  /// The customer's 10 most recent notification reads (newest first).
  final List<AdminCustomerNotification> recentNotifications;
  final AdminNotificationSummary notificationSummary;
}

/// One order of an [AdminCustomerDetail.recentOrders] page.
class AdminCustomerOrder {
  const AdminCustomerOrder({
    required this.id,
    required this.orderNumber,
    required this.total,
    required this.status,
    this.paymentMethod,
    required this.createdAt,
    this.payment,
  });

  final String id;
  final String orderNumber;
  final double total;

  /// Lifecycle status, e.g. `PENDING` (uppercase, server enum).
  final String status;

  /// e.g. `CASH`, `VNPAY`; null while unpaid.
  final String? paymentMethod;
  final DateTime createdAt;

  /// Recorded payment, if one exists yet.
  final AdminCustomerPaymentInfo? payment;
}

/// Payment recorded against an [AdminCustomerOrder].
class AdminCustomerPaymentInfo {
  const AdminCustomerPaymentInfo({
    required this.id,
    required this.provider,
    this.transactionId,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String provider;

  /// Provider-side reference; null for offline payments.
  final String? transactionId;
  final double amount;
  final String status;
  final DateTime createdAt;
}

/// [AdminCustomerPaymentInfo] flattened with the order it paid for, as
/// served by `AdminCustomerDetail.recentPayments`.
class AdminCustomerPayment {
  const AdminCustomerPayment({
    required this.paymentId,
    required this.orderId,
    required this.orderNumber,
    required this.provider,
    this.transactionId,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  final String paymentId;
  final String orderId;
  final String orderNumber;
  final String provider;

  /// Provider-side reference; null for offline payments.
  final String? transactionId;
  final double amount;
  final String status;
  final DateTime createdAt;
}

/// One notification-read entry of an [AdminCustomerDetail].
class AdminCustomerNotification {
  const AdminCustomerNotification({
    required this.notificationId,
    required this.title,
    required this.status,
    required this.audience,
    this.publishedAt,
    required this.createdAt,
    this.readAt,
  });

  final String notificationId;
  final String title;

  /// e.g. `PUBLISHED` (uppercase, server enum).
  final String status;

  /// e.g. `GLOBAL`, `USER`.
  final String audience;

  /// Null while the notification is still scheduled (not sent yet).
  final DateTime? publishedAt;
  final DateTime createdAt;

  /// Null while the customer has not read the notification.
  final DateTime? readAt;
}

/// Read/unread counters for a customer's published notifications.
class AdminNotificationSummary {
  const AdminNotificationSummary({
    this.totalRead = 0,
    this.unreadPublished = 0,
  });

  final int totalRead;
  final int unreadPublished;
}

/// Member levels accepted by the admin customers API (server enum
/// `MemberLevel`). Used to validate the PATCH member-level picker before
/// a request is sent.
class AdminMemberLevel {
  const AdminMemberLevel._();

  static const List<String> values = ['SILVER', 'GOLD', 'PLATINUM'];

  /// True when [value] is exactly one of the server-accepted levels.
  static bool valid(String? value) => values.contains(value);
}
