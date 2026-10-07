import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/admin/dashboard/data/datasources/dashboard_api_service.dart';
import 'package:bakery_mobile/src/features/admin/dashboard/data/repositories/dashboard_repository.dart';
import 'package:bakery_mobile/src/features/admin/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Raw `/api/admin/dashboard` payload — the same shape Task 4's DTO fixture
/// pins (test/dashboard_dto_test.dart): todayOrders 12, todayRevenue 1.250.000,
/// conversionRate 3.2, recentOrders[0] PL-1042/PENDING.
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

/// Fake pattern như test/dashboard_view_model_test.dart: subclass + override.
/// Serves the Task 4 sample JSON, records every requested windowDays and can
/// be primed to throw (error state) before the screen is pumped.
class _FakeDashboardApiService extends DashboardApiService {
  _FakeDashboardApiService()
    : super(
        ApiClient(baseUrl: 'http://localhost:1', tokenProvider: () async => null),
      );

  /// The windowDays argument of every getDashboard call, in order.
  final List<int> windowDaysSeen = [];

  /// When non-null, thrown by every getDashboard call until replaced.
  Object? error;

  @override
  Future<Map<String, dynamic>> getDashboard({int windowDays = 7}) async {
    windowDaysSeen.add(windowDays);
    final thrown = error;
    if (thrown != null) throw thrown;
    return _dashboardPayload;
  }
}

/// Real repository logic over the fake service — the screen consumes the
/// actual `getStats` parsing path, exactly like production.
class _FakeDashboardRepository extends DashboardRepository {
  _FakeDashboardRepository(super.service);
}

Future<void> _pumpDashboardScreen(
  WidgetTester tester,
  _FakeDashboardApiService service,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(
          _FakeDashboardRepository(service),
        ),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const DashboardScreen()),
    ),
  );
}

void main() {
  testWidgets('T1: renders KPI cards and the recent-orders section', (
    tester,
  ) async {
    final service = _FakeDashboardApiService();
    await _pumpDashboardScreen(tester, service);
    // initState kicks off load() post-frame; the polling Timer.periodic never
    // schedules frames, so pumpAndSettle is safe.
    await tester.pumpAndSettle();

    // KPI grid: 'Đơn hôm nay' 12, 'Doanh thu hôm nay' 1.250.000 ₫,
    // 'Tỷ lệ chuyển đổi' 3.2% — and the 'Đơn mới nhất' section header.
    expect(find.text('12'), findsOneWidget);
    expect(find.text('1.250.000 ₫'), findsOneWidget);
    expect(find.text('3.2%'), findsOneWidget);
    expect(find.text('Đơn mới nhất'), findsOneWidget);
    expect(find.text('PL-1042'), findsOneWidget);

    // Unmount so the ProviderScope container is disposed and the screen's
    // auto-refresh timer is cancelled before the test ends.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('T2: tapping the 30-day segment reloads with windowDays 30', (
    tester,
  ) async {
    final service = _FakeDashboardApiService();
    await _pumpDashboardScreen(tester, service);
    await tester.pumpAndSettle();
    expect(service.windowDaysSeen, [7]);

    await tester.tap(find.text('30 ngày'));
    await tester.pump();

    expect(service.windowDaysSeen.last, 30);
    expect(service.windowDaysSeen, [7, 30]);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('T3: recent order renders its StatusPill label', (tester) async {
    final service = _FakeDashboardApiService();
    await _pumpDashboardScreen(tester, service);
    await tester.pumpAndSettle();

    // The 'Trạng thái đơn' KPI card also shows a PENDING pill (orderStates
    // count > 0), so scope to the recent-orders list — it owns exactly one
    // 'Chờ xác nhận' pill for PL-1042.
    expect(
      find.descendant(
        of: find.byKey(const Key('dashboard_recent_orders')),
        matching: find.text('Chờ xác nhận'),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('T4: load failure surfaces the error with a retry button', (
    tester,
  ) async {
    final service = _FakeDashboardApiService();
    service.error = ApiException('boom', statusCode: 500);
    await _pumpDashboardScreen(tester, service);
    await tester.pumpAndSettle();

    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('boom'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('T5: polling tick fires while mounted and stops on dispose', (
    tester,
  ) async {
    final service = _FakeDashboardApiService();
    final scopeOverrides = [
      dashboardRepositoryProvider.overrideWithValue(
        _FakeDashboardRepository(service),
      ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: scopeOverrides,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(service.windowDaysSeen, [7]);

    // The widget-test fake clock fires the Timer.periodic set up by
    // startAutoRefresh() while the screen is mounted.
    await tester.pump(const Duration(minutes: 5));
    expect(service.windowDaysSeen, [7, 7]);

    // Swap the screen out while the ProviderScope (and its keep-alive view
    // model) stays mounted. Without DashboardScreen.dispose() stopping the
    // loop, the keep-alive provider would keep polling forever here — the
    // provider's own ref.onDispose only runs when the whole scope is
    // disposed, which never happens during a session.
    await tester.pumpWidget(
      ProviderScope(
        overrides: scopeOverrides,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(minutes: 5));
    expect(service.windowDaysSeen, [7, 7]);
  });

  testWidgets(
    'T6: failed reload keeps stale stats and shows a retry banner above them',
    (tester) async {
      final service = _FakeDashboardApiService();
      await _pumpDashboardScreen(tester, service);
      await tester.pumpAndSettle();
      expect(find.text('12'), findsOneWidget);

      // Injectable-error pattern (như submitErrors trong
      // test/reviews_controller_test.dart): the first load succeeded, every
      // later call (window switch) fails.
      service.error = ApiException('boom', statusCode: 500);

      await tester.tap(find.text('14 ngày'));
      await tester.pumpAndSettle();

      // Non-blocking banner with a retry action above the still-rendered
      // stale content.
      expect(find.text('Thử lại'), findsOneWidget);
      expect(find.text('boom'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);

      final bannerTop = tester.getTopLeft(find.text('boom')).dy;
      final kpiTop = tester.getTopLeft(find.text('12')).dy;
      expect(bannerTop, lessThan(kpiTop));

      // The newly selected window stays selected despite the failure.
      final segmented = tester.widget<SegmentedButton<int>>(
        find.byType(SegmentedButton<int>),
      );
      expect(segmented.selected, {14});

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
