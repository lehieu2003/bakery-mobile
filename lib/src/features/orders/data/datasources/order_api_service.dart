import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/features/orders/data/dtos/order_dto.dart';

class OrderApiService {
  OrderApiService(this._client);

  final ApiClient _client;

  Future<List<OrderDto>> getMyOrders() async {
    final response = await _client.get('/api/orders');
    final raw =
        (response as Map<String, dynamic>)['orders'] as List<dynamic>? ??
        const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(OrderDto.fromJson)
        .toList();
  }

  Future<CreateOrderResultDto> createOrder({
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    String? customerAddress,
    required String paymentMethod,
    List<String> incentiveCodes = const [],
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
        if (incentiveCodes.isNotEmpty) 'incentiveCodes': incentiveCodes,
        'items': items,
      },
    );

    return CreateOrderResultDto.fromJson(response as Map<String, dynamic>);
  }

  Future<PreviewIncentiveResultDto> previewIncentives({
    required List<String> incentiveCodes,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _client.post(
      '/api/incentives/preview',
      body: {
        if (incentiveCodes.isNotEmpty) 'incentiveCodes': incentiveCodes,
        'items': items,
      },
    );

    return PreviewIncentiveResultDto.fromJson(response as Map<String, dynamic>);
  }

  Future<List<AvailableIncentiveDto>> getAvailableIncentives({
    required double subtotal,
    required List<Map<String, dynamic>> cart,
  }) async {
    final response = await _client.get(
      '/api/incentives/available',
      query: {
        'subtotal': subtotal,
        if (cart.isNotEmpty) 'cart': _serializeCartParam(cart),
      },
    );

    final raw =
        (response as Map<String, dynamic>)['incentives'] as List<dynamic>? ??
        const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AvailableIncentiveDto.fromJson)
        .toList();
  }

  String _serializeCartParam(List<Map<String, dynamic>> cart) {
    final quantityByProductId = <String, int>{};
    for (final item in cart) {
      final productId = item['productId']?.toString().trim() ?? '';
      if (productId.isEmpty) continue;
      final quantity = item['quantity'] is int
          ? item['quantity'] as int
          : int.tryParse('${item['quantity'] ?? ''}') ?? 0;
      if (quantity < 1) continue;
      quantityByProductId[productId] =
          (quantityByProductId[productId] ?? 0) + quantity;
    }

    final entries = quantityByProductId.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return entries.map((entry) => '${entry.key}:${entry.value}').join(',');
  }
}
