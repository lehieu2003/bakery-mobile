import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/admin/orders/data/datasources/order_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/orders/data/repositories/order_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/orders/domain/models/admin_order.dart';
import 'package:bakery_mobile/src/features/admin/orders/presentation/screens/orders_screen.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AdminOrder _order(String orderNumber) {
  final createdAt = DateTime.utc(2026, 10, 7);
  return AdminOrder(
    id: 'id-$orderNumber',
    orderNumber: orderNumber,
    customerName: 'Khách $orderNumber',
    customerPhone: '0901234567',
    status: 'PENDING',
    subtotal: 100000,
    deliveryFee: 0,
    discount: 0,
    total: 100000,
    createdAt: createdAt,
    updatedAt: createdAt,
    items: const [],
  );
}

/// One recorded `getOrders` call.
typedef _Call = ({int page, String? search, String? status});

/// Fake repository: records every getOrders call and serves pages of 2
/// orders out of [totalPages]; [error] (when set) is thrown instead.
class _FakeOrderAdminRepository extends OrderAdminRepository {
  _FakeOrderAdminRepository()
    : super(
        OrderAdminApiService(
          ApiClient(
            baseUrl: 'http://localhost:1',
            tokenProvider: () async => null,
          ),
        ),
      );

  final List<_Call> calls = [];
  int totalPages = 3;
  Object? error;

  @override
  Future<AdminOrderPage> getOrders({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    calls.add((page: page, search: search, status: status));
    final thrown = error;
    if (thrown != null) throw thrown;
    return AdminOrderPage(
      items: [_order('PL-${page}a'), _order('PL-${page}b')],
      totalPages: totalPages,
      total: totalPages * 2,
    );
  }
}

class _FakeAuthViewModel extends AuthViewModel {
  int logoutCalls = 0;

  @override
  AuthState build() => const AuthState(
    user: User(
      id: 'a-1',
      email: 'admin@bakery.vn',
      name: 'Hieu',
      role: 'ADMIN',
    ),
  );

  @override
  Future<void> logout() async {
    logoutCalls++;
    state = state.copyWith(clearUser: true);
  }
}

void main() {
  late _FakeOrderAdminRepository repo;
  late _FakeAuthViewModel auth;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeOrderAdminRepository();
    auth = _FakeAuthViewModel();
    container = ProviderContainer(
      overrides: [
        ordersAdminRepositoryProvider.overrideWithValue(repo),
        authViewModelProvider.overrideWith(() => auth),
      ],
    );
    addTearDown(container.dispose);
  });

  test('load() fetches page 1 with items and totalPages', () async {
    await container.read(ordersAdminViewModelProvider.notifier).load();

    final state = container.read(ordersAdminViewModelProvider);
    expect(repo.calls, [(page: 1, search: null, status: null)]);
    expect(state.items.map((o) => o.orderNumber), ['PL-1a', 'PL-1b']);
    expect(state.page, 1);
    expect(state.totalPages, 3);
    expect(state.total, 6);
    expect(state.hasMore, isTrue);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
  });

  test('setSearch trims, forwards search and resets to page 1', () async {
    final vm = container.read(ordersAdminViewModelProvider.notifier);
    await vm.load();
    await vm.loadMore();
    expect(container.read(ordersAdminViewModelProvider).page, 2);

    await vm.setSearch('  PL-10 ');

    final state = container.read(ordersAdminViewModelProvider);
    expect(repo.calls.last, (page: 1, search: 'PL-10', status: null));
    expect(state.search, 'PL-10');
    expect(state.page, 1);
    expect(state.items.map((o) => o.orderNumber), ['PL-1a', 'PL-1b']);
  });

  test('setStatusFilter forwards status, resets page, null = all', () async {
    final vm = container.read(ordersAdminViewModelProvider.notifier);
    await vm.load();
    await vm.loadMore();

    await vm.setStatusFilter('CONFIRMED');
    expect(repo.calls.last, (page: 1, search: null, status: 'CONFIRMED'));
    expect(container.read(ordersAdminViewModelProvider).page, 1);
    expect(
      container.read(ordersAdminViewModelProvider).statusFilter,
      'CONFIRMED',
    );

    await vm.setStatusFilter(null);
    expect(repo.calls.last, (page: 1, search: null, status: null));
    expect(container.read(ordersAdminViewModelProvider).statusFilter, isNull);
  });

  test('loadMore appends next page while page < totalPages', () async {
    repo.totalPages = 2;
    final vm = container.read(ordersAdminViewModelProvider.notifier);
    await vm.setStatusFilter('PENDING');
    await vm.loadMore();

    var state = container.read(ordersAdminViewModelProvider);
    expect(repo.calls.last, (page: 2, search: null, status: 'PENDING'));
    expect(state.items.map((o) => o.orderNumber), [
      'PL-1a',
      'PL-1b',
      'PL-2a',
      'PL-2b',
    ]);
    expect(state.page, 2);
    expect(state.hasMore, isFalse);

    // Last page reached → loadMore is a no-op.
    await vm.loadMore();
    state = container.read(ordersAdminViewModelProvider);
    expect(repo.calls, hasLength(2));
    expect(state.items, hasLength(4));
  });

  test('generic ApiException surfaces as state.error; retry reloads', () async {
    repo.error = ApiException('Lỗi máy chủ', statusCode: 500);
    final vm = container.read(ordersAdminViewModelProvider.notifier);
    await vm.load();

    var state = container.read(ordersAdminViewModelProvider);
    expect(state.error, 'Lỗi máy chủ');
    expect(state.isLoading, isFalse);
    expect(auth.logoutCalls, 0);

    repo.error = null;
    await vm.retry();
    state = container.read(ordersAdminViewModelProvider);
    expect(state.error, isNull);
    expect(state.items, hasLength(2));
  });

  test(
    'loadMore failure keeps items and sets error; retry loads page',
    () async {
      final vm = container.read(ordersAdminViewModelProvider.notifier);
      await vm.load();
      repo.error = ApiException('Mất kết nối');
      await vm.loadMore();

      var state = container.read(ordersAdminViewModelProvider);
      expect(state.items, hasLength(2));
      expect(state.page, 1);
      expect(state.isLoadingMore, isFalse);
      expect(state.error, 'Mất kết nối');

      repo.error = null;
      await vm.retry();
      state = container.read(ordersAdminViewModelProvider);
      expect(repo.calls.last.page, 2);
      expect(state.items, hasLength(4));
      expect(state.error, isNull);
    },
  );

  test('401 logs out through AuthViewModel and sets no error', () async {
    repo.error = ApiException('Unauthorized', statusCode: 401);
    await container.read(ordersAdminViewModelProvider.notifier).load();

    final state = container.read(ordersAdminViewModelProvider);
    expect(auth.logoutCalls, 1);
    expect(container.read(authViewModelProvider).user, isNull);
    expect(state.error, isNull);
    expect(state.isLoading, isFalse);
  });

  testWidgets('OrdersScreen: cards, status chip and debounced search', (
    tester,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: OrdersScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PL-1a'), findsOneWidget);
    expect(find.text('PL-1b'), findsOneWidget);
    expect(find.text('6 đơn hàng'), findsOneWidget);
    expect(repo.calls, [(page: 1, search: null, status: null)]);

    await tester.tap(find.text('Đã xác nhận'));
    await tester.pumpAndSettle();
    expect(repo.calls.last, (page: 1, search: null, status: 'CONFIRMED'));

    await tester.enterText(find.byType(TextField), 'PL-10');
    await tester.pump(const Duration(milliseconds: 200));
    expect(repo.calls, hasLength(2)); // still debouncing
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(repo.calls.last, (page: 1, search: 'PL-10', status: 'CONFIRMED'));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'PL-10',
    );
  });
}
