import 'package:bakery_mobile/src/features/admin/orders/data/dtos/order_admin_dto.dart';
import 'package:bakery_mobile/src/features/admin/orders/domain/models/admin_order.dart';
import 'package:bakery_mobile/src/features/admin/orders/domain/models/order_audit.dart';
import 'package:bakery_mobile/src/features/admin/shared/utils/json_num.dart';

/// Envelope of `GET /api/admin/orders/{id}/audit` (after `ApiClient`
/// unwraps `data`): `{ logs: [...], pagination: { page, limit, total,
/// totalPages } }`. Reuses the admin orders [AdminOrderPaginationDto].
class OrderAuditPageDto {
  const OrderAuditPageDto({required this.logs, required this.pagination});

  final List<OrderAuditLog> logs;
  final AdminOrderPaginationDto pagination;

  factory OrderAuditPageDto.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'];
    return OrderAuditPageDto(
      logs: parseJsonList(json['logs'], OrderAuditLogDto.fromJson),
      pagination: pagination is Map<String, dynamic>
          ? AdminOrderPaginationDto.fromJson(pagination)
          : const AdminOrderPaginationDto(),
    );
  }
}

/// Parses one audit log row into the [OrderAuditLog] domain model. The
/// actor is `{id, name?, role} | null`; a null actor (or a null name on a
/// present actor) stays null — the UI renders a 'System' fallback.
class OrderAuditLogDto {
  const OrderAuditLogDto._();

  static OrderAuditLog fromJson(Map<String, dynamic> json) {
    final actor = json['actor'];
    final actorMap = actor is Map<String, dynamic> ? actor : null;
    final metadata = json['metadata'];
    return OrderAuditLog(
      id: (json['id'] ?? '').toString(),
      actorName: actorMap == null ? null : actorMap['name']?.toString(),
      // Prefer the role from the joined actor, fall back to the column.
      actorRole: (actorMap?['role'] ?? json['actorRole'])?.toString(),
      mutationType: (json['mutationType'] ?? '').toString(),
      metadata: metadata is Map<String, dynamic> ? metadata : null,
      createdAt:
          DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
    );
  }
}

/// Parses `GET /api/admin/orders/{id}/investigation` (after `ApiClient`
/// unwraps `data`): `{ order, payment?, callbackTimeline,
/// reconciliationAttempts, auditTrail }`. The raw `auditTrail` is dropped
/// on purpose — the UI uses the paginated audit endpoint instead.
class OrderInvestigationDto {
  const OrderInvestigationDto._();

  static OrderInvestigation fromJson(Map<String, dynamic> json) {
    final order = json['order'];
    final orderMap =
        order is Map<String, dynamic> ? order : const <String, dynamic>{};
    final payment = json['payment'];
    return OrderInvestigation(
      orderNumber: (orderMap['orderNumber'] ?? '').toString(),
      orderStatus: (orderMap['status'] ?? '').toString(),
      payment:
          payment is Map<String, dynamic> ? _paymentFromJson(payment) : null,
      callbackEvents: parseJsonList(
        json['callbackTimeline'],
        _callbackEventFromJson,
      ),
      attempts: parseJsonList(
        json['reconciliationAttempts'],
        _reconciliationAttemptFromJson,
      ),
    );
  }

  /// Unlike most money fields, the investigation endpoint emits
  /// `payment.amount` as a plain number (server `Number()`-converts it);
  /// [asNum] tolerates both shapes.
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

  static OrderCallbackEvent _callbackEventFromJson(
    Map<String, dynamic> json,
  ) {
    return OrderCallbackEvent(
      id: (json['id'] ?? '').toString(),
      provider: (json['provider'] ?? '').toString(),
      event: (json['event'] ?? '').toString(),
      incomingStatus: json['incomingStatus']?.toString(),
      existingStatus: json['existingStatus']?.toString(),
      outcome: json['outcome']?.toString(),
      reason: json['reason']?.toString(),
      createdAt:
          DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
    );
  }

  static OrderReconciliationAttempt _reconciliationAttemptFromJson(
    Map<String, dynamic> json,
  ) {
    return OrderReconciliationAttempt(
      callbackEventId: (json['callbackEventId'] ?? '').toString(),
      provider: (json['provider'] ?? '').toString(),
      outcome: (json['outcome'] ?? '').toString(),
      incomingStatus: json['incomingStatus']?.toString(),
      createdAt:
          DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
    );
  }
}
