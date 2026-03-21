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

  Future<CreateOrderResult> createOrder({
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    String? customerAddress,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    final result = await _orderApiService.createOrder(
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      customerAddress: customerAddress,
      paymentMethod: paymentMethod,
      items: items,
    );
    return result.toDomain();
  }
}
