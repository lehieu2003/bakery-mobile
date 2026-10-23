import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/core/utils/idempotency_key.dart';
import 'package:bakery_mobile/src/features/orders/data/datasources/order_api_service.dart';
import 'package:bakery_mobile/src/features/orders/data/repositories/order_repository.dart';
import 'package:bakery_mobile/src/features/orders/domain/models/order.dart';
import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers each createOrder with the next scripted outcome: an exception to
/// throw, or null for success. Records the key every attempt carried.
class _ScriptedOrderRepository extends OrderRepository {
  _ScriptedOrderRepository(this._outcomes)
    : super(
        OrderApiService(
          ApiClient(
            baseUrl: 'http://localhost:1',
            tokenProvider: () async => null,
          ),
        ),
      );

  final List<Object?> _outcomes;
  final keys = <String>[];

  @override
  Future<CreateOrderResult> createOrder({
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    String? customerAddress,
    String? addressId,
    required String paymentMethod,
    required DeliveryMethod deliveryMethod,
    List<String> incentiveCodes = const [],
    required List<Map<String, dynamic>> items,
    required String idempotencyKey,
  }) async {
    keys.add(idempotencyKey);
    final outcome = _outcomes.removeAt(0);
    if (outcome != null) throw outcome;
    return CreateOrderResult(
      order: Order(
        id: 'order-1',
        orderNumber: 'ORD-1',
        status: 'PENDING',
        total: 50000,
        createdAt: DateTime(2026, 1, 1),
        orderItems: const [],
      ),
    );
  }
}

void main() {
  Future<List<String>> placeOrders(List<Object?> outcomes) async {
    final repository = _ScriptedOrderRepository([...outcomes]);
    final container = ProviderContainer(
      overrides: [orderRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final viewModel = container.read(ordersViewModelProvider.notifier);
    for (var i = 0; i < outcomes.length; i++) {
      await viewModel.createOrder(
        customerName: 'A',
        customerPhone: '0901234567',
        paymentMethod: 'COD',
        deliveryMethod: DeliveryMethod.pickup,
        items: const [],
      );
    }
    return repository.keys;
  }

  test('a retry after a transport failure resends the same key', () async {
    final keys = await placeOrders([
      ApiException('Máy chủ phản hồi quá lâu.'), // no status: may have landed
      null,
    ]);
    expect(keys, hasLength(2));
    expect(keys[1], keys[0]);
  });

  test('a new checkout after the server answered uses a new key', () async {
    final keys = await placeOrders([
      ApiException('Out of stock', statusCode: 400),
      null,
      null,
    ]);
    expect(keys.toSet(), hasLength(3));
  });

  test('keys are 32 hex characters, accepted by bakery-web', () {
    expect(newIdempotencyKey(), matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(newIdempotencyKey(), isNot(newIdempotencyKey()));
  });

  test('a 5xx keeps the key: the order may exist (e.g. a 504)', () async {
    final keys = await placeOrders([
      ApiException('Máy chủ đang gặp sự cố.', statusCode: 504),
      null,
    ]);
    expect(keys[1], keys[0]);
  });
}
