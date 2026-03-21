import 'package:bakery_mobile/src/features/orders/domain/models/order.dart';
import 'package:bakery_mobile/src/features/orders/data/datasources/order_api_service.dart';

class OrderRepository {
  OrderRepository(this._orderApiService);

  final OrderApiService _orderApiService;

  Future<List<Order>> getMyOrders() => _orderApiService.getMyOrders();

  Future<CreateOrderResult> createOrder({
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    String? customerAddress,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) {
    return _orderApiService.createOrder(
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      customerAddress: customerAddress,
      paymentMethod: paymentMethod,
      items: items,
    );
  }
}


