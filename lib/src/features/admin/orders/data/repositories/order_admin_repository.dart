import 'package:bakery_mobile/src/features/admin/orders/data/datasources/order_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/orders/data/dtos/order_admin_dto.dart';
import 'package:bakery_mobile/src/features/admin/orders/data/dtos/order_audit_dto.dart';
import 'package:bakery_mobile/src/features/admin/orders/domain/models/admin_order.dart';
import 'package:bakery_mobile/src/features/admin/orders/domain/models/order_audit.dart';

/// One page of the admin orders list.
class AdminOrderPage {
  const AdminOrderPage({
    required this.items,
    required this.totalPages,
    required this.total,
  });

  final List<AdminOrder> items;
  final int totalPages;
  final int total;
}

/// Admin order repository: list, detail and status updates over
/// `/api/admin/orders`.
class OrderAdminRepository {
  const OrderAdminRepository(this._service);

  final OrderAdminApiService _service;

  /// Loads one page of admin orders (newest first). [search] matches order
  /// number / customer name / customer phone; [status] filters by an
  /// uppercase lifecycle status (null = all).
  Future<AdminOrderPage> getOrders({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final payload = await _service.getOrders(
      page: page,
      limit: limit,
      search: search,
      status: status,
    );
    final dto = AdminOrderListDto.fromJson(payload);
    return AdminOrderPage(
      items: dto.orders,
      totalPages: dto.pagination.totalPages,
      total: dto.pagination.total,
    );
  }

  /// Loads one order by id or order number.
  Future<AdminOrder> getOrder(String idOrOrderNumber) async {
    final payload = await _service.getOrder(idOrOrderNumber);
    return AdminOrderDto.fromJson(payload);
  }

  /// Loads one page of an order's audit trail (newest page last, matching
  /// the server's `page`/`limit` semantics). Requires the internal order
  /// [orderId] — the audit route does not resolve order numbers.
  Future<({List<OrderAuditLog> logs, int totalPages})> getOrderAudit(
    String orderId, {
    int page = 1,
    int limit = 20,
  }) async {
    final payload = await _service.getOrderAudit(
      orderId,
      page: page,
      limit: limit,
    );
    final dto = OrderAuditPageDto.fromJson(payload);
    return (logs: dto.logs, totalPages: dto.pagination.totalPages);
  }

  /// Loads the payment investigation (order summary, payment, callback
  /// timeline, reconciliation attempts) for an order. The endpoint's raw
  /// `auditTrail` is not surfaced — use [getOrderAudit] instead.
  Future<OrderInvestigation> getInvestigation(String idOrOrderNumber) async {
    final payload = await _service.getInvestigation(idOrOrderNumber);
    return OrderInvestigationDto.fromJson(payload);
  }

  /// Updates an order's status and/or attaches a note (typically the
  /// cancellation reason); only provided keys are sent. Returns the updated
  /// order parsed from the `{ order: {...} }` response.
  Future<AdminOrder> updateOrder(
    String idOrOrderNumber, {
    String? status,
    String? notes,
  }) async {
    final payload = await _service.updateOrder(
      idOrOrderNumber,
      status: status,
      notes: notes,
    );
    return AdminOrderPatchResultDto.fromJson(payload).order;
  }

  /// Records a manual gateway refund; returns the order as it now stands.
  Future<AdminOrder> markRefunded(String orderId, {String? note}) async {
    await _service.markRefunded(orderId, note: note);
    return getOrder(orderId);
  }
}
