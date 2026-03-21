import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/features/orders/domain/models/order.dart';

class OrderApiService {
  OrderApiService(this._client);

  final ApiClient _client;

  Future<List<Order>> getMyOrders() async {
    final response = await _client.get('/api/orders');
    final raw =
        (response as Map<String, dynamic>)['orders'] as List<dynamic>? ??
        const [];
    return raw.whereType<Map<String, dynamic>>().map(Order.fromJson).toList();
  }

  Future<CreateOrderResult> createOrder({
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    String? customerAddress,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _client.post(
      '/api/orders',
      body: {
        'customerName': customerName,
        'customerPhone': customerPhone,
        if (customerEmail != null && customerEmail.isNotEmpty)
          'customerEmail': customerEmail,
        if (customerAddress != null && customerAddress.isNotEmpty)
          'customerAddress': customerAddress,
        'paymentMethod': paymentMethod,
        'items': items,
      },
    );

    return CreateOrderResult.fromJson(response as Map<String, dynamic>);
  }
}


