import 'package:bakery_mobile/src/features/orders/domain/models/order.dart';
import 'package:bakery_mobile/src/features/orders/data/datasources/order_api_service.dart';

class OrderRepository {
  OrderRepository(this._orderApiService);

  final OrderApiService _orderApiService;

  Future<List<Order>> getMyOrders() async {
    return (await _orderApiService.getMyOrders())
        .map((e) => e.toDomain())
        .toList();
  }

  /// Fetches a single order by its order number.
  /// Throws [ApiException] (statusCode 404) when the order does not exist
  /// or does not belong to the signed-in user.
  Future<Order> getOrder(String orderNumber) async {
    return (await _orderApiService.getOrder(orderNumber)).toDomain();
  }

  Future<CreateOrderResult> createOrder({
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    String? customerAddress,
    String? addressId,
    required String paymentMethod,
    List<String> incentiveCodes = const [],
    required List<Map<String, dynamic>> items,
  }) async {
    final result = await _orderApiService.createOrder(
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      customerAddress: customerAddress,
      addressId: addressId,
      paymentMethod: paymentMethod,
      incentiveCodes: incentiveCodes,
      items: items,
    );
    return result.toDomain();
  }

  Future<PreviewIncentiveResult> previewIncentives({
    required List<String> incentiveCodes,
    required List<Map<String, dynamic>> items,
  }) async {
    final result = await _orderApiService.previewIncentives(
      incentiveCodes: incentiveCodes,
      items: items,
    );
    return result.toDomain();
  }

  Future<List<AvailableIncentive>> getAvailableIncentives({
    required double subtotal,
    required List<Map<String, dynamic>> cart,
  }) async {
    return (await _orderApiService.getAvailableIncentives(
      subtotal: subtotal,
      cart: cart,
    )).map((e) => e.toDomain()).toList();
  }

  Future<PrepareReorderResult> prepareReorder(String orderId) async {
    return (await _orderApiService.prepareReorder(orderId)).toDomain();
  }
}
