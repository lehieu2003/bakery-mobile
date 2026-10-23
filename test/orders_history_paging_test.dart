import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/features/orders/data/datasources/order_api_service.dart';
import 'package:bakery_mobile/src/features/orders/data/repositories/order_repository.dart';
import 'package:bakery_mobile/src/features/orders/domain/models/order.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Order _order(String id) => Order(
  id: id,
  orderNumber: 'BK-$id',
  status: 'PENDING',
  total: 10000,
  createdAt: DateTime(2026, 1, 1),
  orderItems: const [],
);

/// Serves [pages] in order; page N is pages[N-1], with more after it while
/// further pages exist.
class _PagedOrderRepository extends OrderRepository {
  _PagedOrderRepository(this.pages)
    : super(
        OrderApiService(
          ApiClient(
            baseUrl: 'http://localhost:1',
            tokenProvider: () async => null,
          ),
        ),
      );

  final List<List<Order>> pages;
  final requestedPages = <int>[];

  @override
  Future<({List<Order> orders, bool hasMore})> getMyOrders({
    int page = 1,
    int limit = myOrdersPageSize,
  }) async {
    requestedPages.add(page);
    return (orders: pages[page - 1], hasMore: page < pages.length);
  }
}

void main() {
  test('loads the history one page at a time until none remain', () async {
    final repository = _PagedOrderRepository([
      [_order('3'), _order('2')],
      [_order('1')],
    ]);
    final container = ProviderContainer(
      overrides: [orderRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final viewModel = container.read(ordersViewModelProvider.notifier);

    await viewModel.loadMyOrders();
    expect(container.read(ordersViewModelProvider).hasMoreOrders, isTrue);

    await viewModel.loadMoreOrders();
    final state = container.read(ordersViewModelProvider);
    expect(state.orders.map((o) => o.id), ['3', '2', '1']);
    expect(state.hasMoreOrders, isFalse);

    // Nothing left: no further request.
    await viewModel.loadMoreOrders();
    expect(repository.requestedPages, [1, 2]);
  });

  test('orders shifted onto the next page are not shown twice', () async {
    // An order placed after page 1 loaded pushes '2' onto page 2.
    final repository = _PagedOrderRepository([
      [_order('3'), _order('2')],
      [_order('2'), _order('1')],
    ]);
    final container = ProviderContainer(
      overrides: [orderRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final viewModel = container.read(ordersViewModelProvider.notifier);

    await viewModel.loadMyOrders();
    await viewModel.loadMoreOrders();

    expect(container.read(ordersViewModelProvider).orders.map((o) => o.id), [
      '3',
      '2',
      '1',
    ]);
  });
}
