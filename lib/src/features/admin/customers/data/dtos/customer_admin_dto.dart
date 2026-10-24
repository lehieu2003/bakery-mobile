import 'package:bakery_mobile/src/features/admin/customers/domain/models/admin_customer.dart';
import 'package:bakery_mobile/src/features/admin/shared/utils/json_num.dart';

/// Parses an admin customer list row into the [AdminCustomer] domain model.
/// Every field is read defensively: money may arrive as numeric strings or
/// numbers (`totalSpent`), `name`/`phone` may be null, and the duplicate
/// `level` alias of `memberLevel` is ignored.
class AdminCustomerDto {
  const AdminCustomerDto._();

  static AdminCustomer fromJson(Map<String, dynamic> json) {
    return AdminCustomer(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      memberLevel: (json['memberLevel'] ?? '').toString(),
      points: asNum(json['points']).toInt(),
      isActive: json['isActive'] == true,
      createdAt:
          DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
      totalOrders: asNum(json['totalOrders']).toInt(),
      totalSpent: asNum(json['totalSpent']).toDouble(),
    );
  }
}

/// Parses the customer detail payload returned by
/// `GET /api/admin/customers/{id}` and `PATCH /api/admin/customers/{id}`
/// (both return the customer object directly) into an [AdminCustomerDetail].
class AdminCustomerDetailDto {
  const AdminCustomerDetailDto._();

  static AdminCustomerDetail fromJson(Map<String, dynamic> json) {
    final summary = json['notificationSummary'];
    return AdminCustomerDetail(
      id: (json['id'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      memberLevel: (json['memberLevel'] ?? '').toString(),
      points: asNum(json['points']).toInt(),
      isActive: json['isActive'] == true,
      createdAt:
          DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
      totalOrders: asNum(json['totalOrders']).toInt(),
      totalSpent: asNum(json['totalSpent']).toDouble(),
      recentOrders: parseJsonList(json['recentOrders'], _orderFromJson),
      recentPayments: parseJsonList(json['recentPayments'], _paymentFromJson),
      recentNotifications: parseJsonList(
        json['recentNotifications'],
        _notificationFromJson,
      ),
      notificationSummary: summary is Map<String, dynamic>
          ? AdminNotificationSummary(
              totalRead: asNum(summary['totalRead']).toInt(),
              unreadPublished: asNum(summary['unreadPublished']).toInt(),
            )
          : const AdminNotificationSummary(),
    );
  }

  static AdminCustomerOrder _orderFromJson(Map<String, dynamic> json) {
    final payment = json['payment'];
    return AdminCustomerOrder(
      id: (json['id'] ?? '').toString(),
      orderNumber: (json['orderNumber'] ?? '').toString(),
      total: asNum(json['total']).toDouble(),
      status: (json['status'] ?? '').toString(),
      paymentMethod: json['paymentMethod']?.toString(),
      createdAt:
          DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
      payment: payment is Map<String, dynamic> ? _paymentInfoFromJson(payment) : null,
    );
  }

  static AdminCustomerPaymentInfo _paymentInfoFromJson(
    Map<String, dynamic> json,
  ) {
    return AdminCustomerPaymentInfo(
      id: (json['id'] ?? '').toString(),
      provider: (json['provider'] ?? '').toString(),
      transactionId: json['transactionId']?.toString(),
      amount: asNum(json['amount']).toDouble(),
      status: (json['status'] ?? '').toString(),
      createdAt:
          DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
    );
  }

  static AdminCustomerPayment _paymentFromJson(Map<String, dynamic> json) {
    return AdminCustomerPayment(
      paymentId: (json['paymentId'] ?? '').toString(),
      orderId: (json['orderId'] ?? '').toString(),
      orderNumber: (json['orderNumber'] ?? '').toString(),
      provider: (json['provider'] ?? '').toString(),
      transactionId: json['transactionId']?.toString(),
      amount: asNum(json['amount']).toDouble(),
      status: (json['status'] ?? '').toString(),
      createdAt:
          DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
    );
  }

  static AdminCustomerNotification _notificationFromJson(
    Map<String, dynamic> json,
  ) {
    return AdminCustomerNotification(
      notificationId: (json['notificationId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      audience: (json['audience'] ?? '').toString(),
      publishedAt: json['publishedAt'] == null
          ? null
          : DateTime.tryParse('${json['publishedAt']}'),
      createdAt:
          DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
      readAt: json['readAt'] == null
          ? null
          : DateTime.tryParse('${json['readAt']}'),
    );
  }
}

/// Envelope of `GET /api/admin/customers` (after `ApiClient` unwraps `data`):
/// `{ customers: [...], pagination: { page, limit, total, totalPages } }`.
class AdminCustomerListDto {
  const AdminCustomerListDto({required this.customers, required this.pagination});

  final List<AdminCustomer> customers;
  final AdminCustomerPaginationDto pagination;

  factory AdminCustomerListDto.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'];
    return AdminCustomerListDto(
      customers: parseJsonList(json['customers'], AdminCustomerDto.fromJson),
      pagination: pagination is Map<String, dynamic>
          ? AdminCustomerPaginationDto.fromJson(pagination)
          : const AdminCustomerPaginationDto(),
    );
  }
}

/// `pagination` block of the admin customers list envelope.
class AdminCustomerPaginationDto {
  const AdminCustomerPaginationDto({
    this.page = 0,
    this.limit = 0,
    this.total = 0,
    this.totalPages = 0,
  });

  final int page;
  final int limit;
  final int total;
  final int totalPages;

  factory AdminCustomerPaginationDto.fromJson(Map<String, dynamic> json) {
    return AdminCustomerPaginationDto(
      page: asNum(json['page']).toInt(),
      limit: asNum(json['limit']).toInt(),
      total: asNum(json['total']).toInt(),
      totalPages: asNum(json['totalPages']).toInt(),
    );
  }
}
