import 'package:bakery_mobile/src/features/orders/data/repositories/order_repository.dart';
import 'package:bakery_mobile/src/features/orders/domain/models/order.dart';

class OrderCheckoutService {
  OrderCheckoutService(this._orderRepository);

  final OrderRepository _orderRepository;

  Future<CreateOrderResult> createOrder({
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    String? customerAddress,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) {
    return _orderRepository.createOrder(
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      customerAddress: customerAddress,
      paymentMethod: paymentMethod,
      items: items,
    );
  }
}
