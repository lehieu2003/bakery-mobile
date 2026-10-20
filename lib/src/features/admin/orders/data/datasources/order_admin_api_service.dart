import 'package:bakery_mobile/src/core/network/api_client.dart';

/// Thin datasource over `/api/admin/orders`. Methods deal in raw JSON maps
/// so tests can substitute a fake [ApiClient] without knowing about DTO
/// parsing.
class OrderAdminApiService {
  const OrderAdminApiService(this._client);

  final ApiClient _client;

  /// GET /api/admin/orders — paginated admin order list (newest first).
  /// [search] matches order number / customer name / customer phone
  /// server-side; [status] filters by an uppercase lifecycle status.
  /// Requires the ADMIN role. Returns `{ orders: [...], pagination: {...} }`.
  Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final response = await _client.get(
      '/api/admin/orders',
      query: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    return response as Map<String, dynamic>? ?? const {};
  }

  /// GET /api/admin/orders/{id} — order detail by id or order number.
  /// Returns the order object directly.
  Future<Map<String, dynamic>> getOrder(String idOrOrderNumber) async {
    final response = await _client.get('/api/admin/orders/$idOrOrderNumber');
    return response as Map<String, dynamic>? ?? const {};
  }

  /// GET /api/admin/orders/{id}/audit — paginated audit trail for an order.
  /// Unlike the other order routes the server matches the internal order
  /// [orderId] only: an order number returns an empty page, not a 404.
  /// Returns `{ logs: [...], pagination: {...} }`.
  Future<Map<String, dynamic>> getOrderAudit(
    String orderId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _client.get(
      '/api/admin/orders/$orderId/audit',
      query: {'page': page, 'limit': limit},
    );
    return response as Map<String, dynamic>? ?? const {};
  }

  /// GET /api/admin/orders/{id}/investigation — payment forensics for an
  /// order by id or order number. Returns `{ order, payment?, callbackTimeline,
  /// reconciliationAttempts, auditTrail }`.
  Future<Map<String, dynamic>> getInvestigation(String idOrOrderNumber) async {
    final response = await _client.get(
      '/api/admin/orders/$idOrOrderNumber/investigation',
    );
    return response as Map<String, dynamic>? ?? const {};
  }

  /// PATCH /api/admin/orders/{id} — update status and/or attach a note
  /// (typically the cancellation reason). Only non-null keys are sent; the
  /// server re-validates the transition. Returns `{ order: {...} }`.
  Future<Map<String, dynamic>> updateOrder(
    String idOrOrderNumber, {
    String? status,
    String? notes,
  }) async {
    final response = await _client.patch(
      '/api/admin/orders/$idOrOrderNumber',
      body: {
        if (status != null) 'status': status,
        if (notes != null) 'notes': notes,
      },
    );
    return response as Map<String, dynamic>? ?? const {};
  }
}
