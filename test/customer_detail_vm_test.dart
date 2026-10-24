import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/admin/customers/data/datasources/customer_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/customers/data/repositories/customer_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/customers/domain/models/admin_customer.dart';
import 'package:bakery_mobile/src/features/admin/customers/presentation/controllers/customer_detail_view_model.dart';
import 'package:bakery_mobile/src/features/admin/customers/presentation/screens/customer_detail_screen.dart';
import 'package:bakery_mobile/src/features/admin/customers/presentation/screens/customers_screen.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors Task 1's `customer_admin_dto_test.dart` detail fixture (T3): the
/// same customer, recents and notification summary the DTO test pins.
AdminCustomerDetail _detail() {
  return AdminCustomerDetail(
    id: 'cus-1',
    email: 'an@example.com',
    name: 'Nguyễn Văn A',
    phone: '0901234567',
    memberLevel: 'GOLD',
    points: 120,
    isActive: true,
    createdAt: DateTime.utc(2026, 1, 15, 8, 30),
    totalOrders: 12,
    totalSpent: 2450000.5,
    recentOrders: [
      AdminCustomerOrder(
        id: 'ord-1',
        orderNumber: 'PL-1042',
        total: 875000,
        status: 'COMPLETED',
        paymentMethod: 'VNPAY',
        createdAt: DateTime.utc(2026, 10, 7, 9, 30),
        payment: AdminCustomerPaymentInfo(
          id: 'pay-1',
          provider: 'VNPAY',
          transactionId: 'TXN-889',
          amount: 875000,
          status: 'PAID',
          createdAt: DateTime.utc(2026, 10, 7, 9, 31),
        ),
      ),
      AdminCustomerOrder(
        id: 'ord-2',
        orderNumber: 'PL-1043',
        total: 120000,
        status: 'PENDING',
        paymentMethod: null, // unpaid order carries no method
        createdAt: DateTime.utc(2026, 10, 20, 10),
        payment: null, // no payment recorded yet
      ),
    ],
    recentPayments: [
      AdminCustomerPayment(
        paymentId: 'pay-1',
        orderId: 'ord-1',
        orderNumber: 'PL-1042',
        provider: 'VNPAY',
        transactionId: 'TXN-889',
        amount: 875000,
        status: 'PAID',
        createdAt: DateTime.utc(2026, 10, 7, 9, 31),
      ),
    ],
    recentNotifications: [
      AdminCustomerNotification(
        notificationId: 'noti-1',
        title: 'Khuyến mãi cuối tuần',
        status: 'PUBLISHED',
        audience: 'GLOBAL',
        publishedAt: DateTime.utc(2026, 10, 1, 7),
        createdAt: DateTime.utc(2026, 10, 1, 6),
        readAt: DateTime.utc(2026, 10, 2, 9),
      ),
      AdminCustomerNotification(
        notificationId: 'noti-2',
        title: 'Nhắc giờ lấy bánh',
        status: 'PUBLISHED',
        audience: 'USER',
        publishedAt: null, // scheduled, not sent yet
        createdAt: DateTime.utc(2026, 10, 5, 6),
        readAt: null, // unread
      ),
    ],
    notificationSummary: const AdminNotificationSummary(
      totalRead: 3,
      unreadPublished: 1,
    ),
  );
}

/// Fake repository: records every getCustomer id; [error] (when set) is
/// thrown instead of the fixture detail. Also serves one list page for the
/// navigation test.
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

  final List<String> calls = [];
  Object? error;

  @override
  Future<AdminCustomerDetail> getCustomer(String id) async {
    calls.add(id);
    final thrown = error;
    if (thrown != null) throw thrown;
    return _detail();
  }

  @override
  Future<CustomerAdminPage> getCustomers({
    int page = 1,
    int limit = 50,
    String? search,
    String? level,
  }) async {
    final thrown = error;
    if (thrown != null) throw thrown;
    return CustomerAdminPage(
      items: [
        AdminCustomer(
          id: 'cus-1',
          email: 'an@example.com',
          name: 'Nguyễn Văn A',
          phone: '0901234567',
          memberLevel: 'GOLD',
          points: 120,
          isActive: true,
          createdAt: DateTime.utc(2026, 1, 15, 8, 30),
          totalOrders: 12,
          totalSpent: 2450000.5,
        ),
      ],
      totalPages: 1,
      total: 1,
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

  CustomerDetailViewModel vm() =>
      container.read(customerDetailViewModelProvider('cus-1').notifier);
  CustomerDetailState state() =>
      container.read(customerDetailViewModelProvider('cus-1'));

  test('load() fetches the detail with recents and notification summary', () async {
    await vm().load();

    expect(repo.calls, ['cus-1']);
    final detail = state().detail;
    expect(detail, isNotNull);
    expect(detail!.id, 'cus-1');
    expect(detail.email, 'an@example.com');
    expect(detail.name, 'Nguyễn Văn A');
    expect(detail.memberLevel, 'GOLD');
    expect(detail.points, 120);
    expect(detail.totalOrders, 12);
    expect(detail.totalSpent, 2450000.5);
    // Recent orders: paid one carries its payment, unpaid one has none.
    expect(detail.recentOrders, hasLength(2));
    expect(detail.recentOrders[0].orderNumber, 'PL-1042');
    expect(detail.recentOrders[0].payment!.transactionId, 'TXN-889');
    expect(detail.recentOrders[1].payment, isNull);
    // Flattened payments and notifications, with the read/unread summary.
    expect(detail.recentPayments.single.transactionId, 'TXN-889');
    expect(detail.recentNotifications[0].readAt, isNotNull);
    expect(detail.recentNotifications[1].readAt, isNull);
    expect(detail.notificationSummary.totalRead, 3);
    expect(detail.notificationSummary.unreadPublished, 1);
    expect(state().isLoading, isFalse);
    expect(state().error, isNull);
  });

  test('401 on load logs out through AuthViewModel and sets no error', () async {
    repo.error = ApiException('Unauthorized', statusCode: 401);
    await vm().load();

    expect(auth.logoutCalls, 1);
    expect(container.read(authViewModelProvider).user, isNull);
    expect(state().error, isNull);
    expect(state().isLoading, isFalse);
  });

  test('generic error surfaces as state.error; retry re-calls the repo', () async {
    repo.error = ApiException('Lỗi máy chủ', statusCode: 500);
    await vm().load();

    var current = state();
    expect(current.error, 'Lỗi máy chủ');
    expect(current.detail, isNull);
    expect(current.isLoading, isFalse);
    expect(auth.logoutCalls, 0);

    repo.error = null;
    await vm().retry();
    current = state();
    expect(repo.calls, ['cus-1', 'cus-1']);
    expect(current.error, isNull);
    expect(current.detail!.id, 'cus-1');
  });

  testWidgets('CustomerDetailScreen renders header, stats, recents and summary',
      (tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const CustomerDetailScreen(customerId: 'cus-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repo.calls, ['cus-1']);
    // Header: name, email, tier badge, edit button (Task 4 wires the sheet).
    expect(find.text('Nguyễn Văn A'), findsOneWidget);
    expect(find.text('an@example.com'), findsOneWidget);
    expect(find.text('GOLD'), findsOneWidget);
    expect(find.text('Chỉnh sửa'), findsOneWidget);
    // 3 stat cards.
    expect(find.text('Tổng đơn'), findsOneWidget);
    expect(find.text('Tổng chi'), findsOneWidget);
    expect(find.text('Điểm'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    // Recent orders with Vietnamese status labels.
    expect(find.text('PL-1042'), findsOneWidget);
    expect(find.text('PL-1043'), findsOneWidget);
    expect(find.text('Hoàn thành'), findsOneWidget);
    expect(find.text('Chờ xác nhận'), findsOneWidget);
    // Recent payments, then scroll down to the notifications section.
    expect(find.text('VNPAY · PL-1042'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('3 đã đọc · 1 chưa đọc'),
      200,
    );
    expect(find.text('Khuyến mãi cuối tuần'), findsOneWidget);
    expect(find.text('Nhắc giờ lấy bánh'), findsOneWidget);
    expect(find.text('Chưa đọc'), findsOneWidget);
    expect(find.text('Đã đọc'), findsOneWidget);
    expect(find.text('3 đã đọc · 1 chưa đọc'), findsOneWidget);
  });

  testWidgets('tapping a customer card pushes the detail screen', (
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

    expect(find.text('Nguyễn Văn A'), findsOneWidget); // list card

    await tester.tap(find.text('Nguyễn Văn A'));
    await tester.pumpAndSettle();

    // Detail pushed (root navigator) and loaded for the tapped id.
    expect(find.byType(CustomerDetailScreen), findsOneWidget);
    expect(find.text('Chi tiết khách hàng'), findsOneWidget);
    expect(repo.calls, ['cus-1']);
    expect(find.text('Tổng chi'), findsOneWidget);
  });
}
