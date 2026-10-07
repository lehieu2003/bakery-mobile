import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/dashboard/data/datasources/dashboard_api_service.dart';
import 'package:bakery_mobile/src/features/admin/dashboard/data/repositories/dashboard_repository.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Raw `/api/admin/dashboard` payload — the same shape Task 4's DTO fixture
/// pins (test/dashboard_dto_test.dart), so these tests only care about call
/// bookkeeping, not parsing.
const Map<String, dynamic> _dashboardPayload = {
  'kpi': {
    'todayOrders': 12,
    'todayRevenue': '1250000',
    'pendingOrders': 3,
    'totalCustomers': 48,
    'totalProducts': 46,
    'periodOrders': 96,
    'periodCompletedOrders': 81,
    'periodCancelledOrders': 4,
    'conversionRate': 3.2,
  },
  'chartData': [
    {
      'day': '2026-10-06',
      'orders': 9,
      'revenue': 890000,
      'completedOrders': 7,
      'cancelledOrders': 1,
    },
    {
      'day': '2026-10-07',
      'orders': 12,
      'revenue': '1250000',
      'completedOrders': 9,
      'cancelledOrders': 0,
    },
  ],
  'orderStates': [
    {'status': 'PENDING', 'count': 3},
    {'status': 'COMPLETED', 'count': 81},
  ],
  'recentOrders': [
    {
      'id': 'o-1',
      'orderNumber': 'PL-1042',
      'customerName': 'Nguyễn Văn A',
      'total': '250000',
      'status': 'PENDING',
      'createdAt': '2026-10-07T09:30:00.000Z',
      'itemsCount': 2,
    },
  ],
  'meta': {'windowDays': 7, 'refreshIntervalSeconds': 300},
};

/// Fake pattern như test/reviews_controller_test.dart: subclass + override.
/// Counts every getDashboard call, records the requested windowDays, and
/// can be primed to throw on subsequent calls.
class _FakeDashboardApiService extends DashboardApiService {
  _FakeDashboardApiService()
    : super(
        ApiClient(baseUrl: 'http://localhost:1', tokenProvider: () async => null),
      );

  /// Total number of getDashboard calls — the polling tests assert on this.
  int calls = 0;

  /// The windowDays argument of every getDashboard call, in order.
  final List<int> windowDaysSeen = [];

  /// When non-null, thrown by every getDashboard call until replaced.
  Object? error;

  @override
  Future<Map<String, dynamic>> getDashboard({int windowDays = 7}) async {
    calls++;
    windowDaysSeen.add(windowDays);
    final thrown = error;
    if (thrown != null) throw thrown;
    return _dashboardPayload;
  }
}

/// Real repository logic over the fake service — proves the VM works
/// through the actual `getStats` parsing path.
class _FakeDashboardRepository extends DashboardRepository {
  _FakeDashboardRepository(super.service);
}

ProviderContainer _container(_FakeDashboardApiService service) {
  return ProviderContainer(
    overrides: [
      dashboardRepositoryProvider.overrideWithValue(
        _FakeDashboardRepository(service),
      ),
    ],
  );
}

void main() {
  test('load() fetches stats for the default 7-day window', () async {
    final service = _FakeDashboardApiService();
    final container = _container(service);
    addTearDown(container.dispose);

    await container.read(dashboardViewModelProvider.notifier).load();

    final state = container.read(dashboardViewModelProvider);
    expect(state.stats, isNotNull);
    expect(state.stats!.kpi.todayOrders, 12);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.windowDays, 7);
    expect(service.windowDaysSeen, [7]);
  });

  test('setWindow() switches the window and refetches with it', () async {
    final service = _FakeDashboardApiService();
    final container = _container(service);
    addTearDown(container.dispose);
    final vm = container.read(dashboardViewModelProvider.notifier);

    await vm.load();
    await vm.setWindow(14);

    expect(service.windowDaysSeen, [7, 14]);
    expect(service.windowDaysSeen.last, 14);
    final state = container.read(dashboardViewModelProvider);
    expect(state.windowDays, 14);
    expect(state.stats, isNotNull);
    expect(state.isLoading, isFalse);
  });

  test('load() failure maps the ApiException message to state.error', () async {
    final service = _FakeDashboardApiService();
    service.error = ApiException('boom', statusCode: 500);
    final container = _container(service);
    addTearDown(container.dispose);

    await container.read(dashboardViewModelProvider.notifier).load();

    final state = container.read(dashboardViewModelProvider);
    expect(state.error, 'boom');
    expect(state.stats, isNull);
    expect(state.isLoading, isFalse);
  });

  test('startAutoRefresh polls ~every 5 minutes and stops after dispose', () {
    fakeAsync((async) {
      final service = _FakeDashboardApiService();
      final container = _container(service);
      final vm = container.read(dashboardViewModelProvider.notifier);

      vm.startAutoRefresh();
      async.elapse(const Duration(minutes: 10));
      expect(
        service.calls,
        greaterThanOrEqualTo(2),
        reason: 'two 5-minute ticks fit inside a 10-minute window',
      );

      container.dispose();
      final before = service.calls;
      async.elapse(const Duration(minutes: 5));
      expect(
        service.calls,
        before,
        reason: 'the periodic timer must be cancelled when the VM is disposed',
      );
    });
  });

  test('stopAutoRefresh() freezes an already-running polling loop', () {
    fakeAsync((async) {
      final service = _FakeDashboardApiService();
      final container = _container(service);
      addTearDown(container.dispose);
      final vm = container.read(dashboardViewModelProvider.notifier);

      vm.startAutoRefresh();
      async.elapse(const Duration(minutes: 5));
      expect(service.calls, 1, reason: 'the loop is running before the stop');

      vm.stopAutoRefresh();
      async.elapse(const Duration(minutes: 10));
      expect(
        service.calls,
        1,
        reason: 'stop must cancel the periodic timer for good',
      );
    });
  });

  test('stopAutoRefresh() is a no-op when the loop never started', () {
    fakeAsync((async) {
      final service = _FakeDashboardApiService();
      final container = _container(service);
      addTearDown(container.dispose);

      container.read(dashboardViewModelProvider.notifier).stopAutoRefresh();
      async.elapse(const Duration(minutes: 5));

      expect(service.calls, 0);
    });
  });

  test('calling startAutoRefresh() twice keeps a single polling timer', () {
    fakeAsync((async) {
      final service = _FakeDashboardApiService();
      final container = _container(service);
      final vm = container.read(dashboardViewModelProvider.notifier);

      vm.startAutoRefresh();
      vm.startAutoRefresh();
      async.elapse(const Duration(minutes: 10));

      expect(
        service.calls,
        2,
        reason: 'the second start must cancel the first timer, not stack one',
      );

      container.dispose();
      async.elapse(const Duration(minutes: 5));
      expect(service.calls, 2);
    });
  });
}
