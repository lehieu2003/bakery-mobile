import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/admin/customers/data/datasources/customer_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/customers/data/repositories/customer_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/customers/domain/models/admin_customer.dart';
import 'package:bakery_mobile/src/features/admin/customers/presentation/controllers/customers_admin_view_model.dart';
import 'package:bakery_mobile/src/features/admin/customers/presentation/screens/customers_screen.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AdminCustomer _customer(String email, {String level = 'SILVER'}) {
  return AdminCustomer(
    id: 'id-$email',
    email: email,
    name: 'Khách $email',
    phone: '0901234567',
    memberLevel: level,
    points: 120,
    isActive: true,
    createdAt: DateTime.utc(2026, 10, 7),
    totalOrders: 3,
    totalSpent: 250000,
  );
}

/// One recorded `getCustomers` call.
typedef _Call = ({int page, String? search, String? level});

/// Fake repository: records every getCustomers call and serves pages of 2
/// customers out of [totalPages]; [error] (when set) is thrown instead.
class _FakeCustomerAdminRepository extends CustomerAdminRepository {
  _FakeCustomerAdminRepository()
    : super(
        CustomerAdminApiService(
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
  Future<CustomerAdminPage> getCustomers({
    int page = 1,
    int limit = 50,
    String? search,
    String? level,
  }) async {
    calls.add((page: page, search: search, level: level));
    final thrown = error;
    if (thrown != null) throw thrown;
    return CustomerAdminPage(
      items: [
        _customer('p${page}a@bakery.vn', level: level ?? 'SILVER'),
        _customer('p${page}b@bakery.vn', level: 'GOLD'),
      ],
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
  late _FakeCustomerAdminRepository repo;
  late _FakeAuthViewModel auth;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeCustomerAdminRepository();
    auth = _FakeAuthViewModel();
    container = ProviderContainer(
      overrides: [
        customersAdminRepositoryProvider.overrideWithValue(repo),
        authViewModelProvider.overrideWith(() => auth),
      ],
    );
    addTearDown(container.dispose);
  });

  test('load() fetches page 1 with items and totalPages', () async {
    await container.read(customersAdminViewModelProvider.notifier).load();

    final state = container.read(customersAdminViewModelProvider);
    expect(repo.calls, [(page: 1, search: null, level: null)]);
    expect(state.items.map((c) => c.email), ['p1a@bakery.vn', 'p1b@bakery.vn']);
    expect(state.page, 1);
    expect(state.totalPages, 3);
    expect(state.total, 6);
    expect(state.hasMore, isTrue);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
  });

  test('setSearch trims, forwards search and resets to page 1', () async {
    final vm = container.read(customersAdminViewModelProvider.notifier);
    await vm.load();
    await vm.loadMore();
    expect(container.read(customersAdminViewModelProvider).page, 2);

    await vm.setSearch('  linh ');

    final state = container.read(customersAdminViewModelProvider);
    expect(repo.calls.last, (page: 1, search: 'linh', level: null));
    expect(state.search, 'linh');
    expect(state.page, 1);
    expect(state.items.map((c) => c.email), ['p1a@bakery.vn', 'p1b@bakery.vn']);
  });

  test("setFilter forwards level, 'ALL' clears it, resets page", () async {
    final vm = container.read(customersAdminViewModelProvider.notifier);
    await vm.load();
    await vm.loadMore();

    await vm.setFilter('GOLD');
    expect(repo.calls.last, (page: 1, search: null, level: 'GOLD'));
    expect(container.read(customersAdminViewModelProvider).page, 1);
    expect(container.read(customersAdminViewModelProvider).levelFilter, 'GOLD');

    await vm.setFilter('ALL');
    expect(repo.calls.last, (page: 1, search: null, level: null));
    expect(container.read(customersAdminViewModelProvider).levelFilter, isNull);
  });

  test('loadMore appends next page while page < totalPages', () async {
    repo.totalPages = 2;
    final vm = container.read(customersAdminViewModelProvider.notifier);
    await vm.setFilter('GOLD');
    await vm.loadMore();

    var state = container.read(customersAdminViewModelProvider);
    expect(repo.calls.last, (page: 2, search: null, level: 'GOLD'));
    expect(state.items.map((c) => c.email), [
      'p1a@bakery.vn',
      'p1b@bakery.vn',
      'p2a@bakery.vn',
      'p2b@bakery.vn',
    ]);
    expect(state.page, 2);
    expect(state.hasMore, isFalse);

    // Last page reached → loadMore is a no-op.
    await vm.loadMore();
    state = container.read(customersAdminViewModelProvider);
    expect(repo.calls, hasLength(2));
    expect(state.items, hasLength(4));
  });

  test('generic ApiException surfaces as state.error; retry reloads', () async {
    repo.error = ApiException('Lỗi máy chủ', statusCode: 500);
    final vm = container.read(customersAdminViewModelProvider.notifier);
    await vm.load();

    var state = container.read(customersAdminViewModelProvider);
    expect(state.error, 'Lỗi máy chủ');
    expect(state.isLoading, isFalse);
    expect(auth.logoutCalls, 0);

    repo.error = null;
    await vm.retry();
    state = container.read(customersAdminViewModelProvider);
    expect(state.error, isNull);
    expect(state.items, hasLength(2));
  });

  test('401 logs out through AuthViewModel and sets no error', () async {
    repo.error = ApiException('Unauthorized', statusCode: 401);
    await container.read(customersAdminViewModelProvider.notifier).load();

    final state = container.read(customersAdminViewModelProvider);
    expect(auth.logoutCalls, 1);
    expect(container.read(authViewModelProvider).user, isNull);
    expect(state.error, isNull);
    expect(state.isLoading, isFalse);
  });

  testWidgets('CustomersScreen: cards, tier chip and debounced search', (
    tester,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: CustomersScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Khách p1a@bakery.vn'), findsOneWidget);
    expect(find.text('p1a@bakery.vn'), findsOneWidget);
    expect(find.text('120 điểm'), findsNWidgets(2));
    // 'GOLD' appears twice: the filter chip and the badge on card 2.
    expect(find.text('GOLD'), findsNWidgets(2));
    expect(
      find.descendant(of: find.byType(Card), matching: find.text('GOLD')),
      findsOneWidget,
    );
    expect(repo.calls, [(page: 1, search: null, level: null)]);

    // The badge text equals the chip label → target the chip by type.
    await tester.tap(find.widgetWithText(ChoiceChip, 'SILVER'));
    await tester.pumpAndSettle();
    expect(repo.calls.last, (page: 1, search: null, level: 'SILVER'));

    await tester.enterText(find.byType(TextField), 'linh');
    await tester.pump(const Duration(milliseconds: 200));
    expect(repo.calls, hasLength(2)); // still debouncing
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(repo.calls.last, (page: 1, search: 'linh', level: 'SILVER'));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'linh',
    );
  });
}
