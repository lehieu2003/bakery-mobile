import 'package:bakery_mobile/src/features/admin/dashboard/data/dtos/dashboard_dto.dart';
import 'package:bakery_mobile/src/features/admin/dashboard/domain/models/dashboard_stats.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixture mirrors the admin dashboard payload shape pinned from
/// `bakery-web/types/api.types.ts` (DashboardStats). Numeric fields may
/// arrive as JSON numbers or strings — the string cases pin the
/// string→num coercion done by the DTO.
const Map<String, dynamic> sample = {
  'kpi': {
    'todayOrders': 12,
    'todayRevenue': '1250000', // string — ghim coercion
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

void main() {
  group('DashboardStatsDto', () {
    test('parses the full sample, coercing numeric strings', () {
      final stats = DashboardStatsDto.fromJson(sample).toDomain();

      expect(stats.kpi.todayRevenue, 1250000.0);
      expect(stats.kpi.todayRevenue, isA<double>());
      expect(stats.kpi.todayOrders, 12);
      expect(stats.kpi.pendingOrders, 3);
      expect(stats.kpi.totalCustomers, 48);
      expect(stats.kpi.totalProducts, 46);
      expect(stats.kpi.periodOrders, 96);
      expect(stats.kpi.periodCompletedOrders, 81);
      expect(stats.kpi.periodCancelledOrders, 4);
      expect(stats.kpi.conversionRate, 3.2);

      expect(stats.chartData, hasLength(2));
      expect(stats.chartData[1].revenue, 1250000.0);
      expect(stats.chartData[1].revenue, isA<double>());

      expect(stats.recentOrders, hasLength(1));
      expect(stats.recentOrders[0].total, 250000.0);
      expect(stats.recentOrders[0].total, isA<double>());
      expect(stats.recentOrders[0].createdAt, DateTime.utc(2026, 10, 7, 9, 30));
    });

    test('falls back to zeroed defaults for an empty payload', () {
      final stats = DashboardStatsDto.fromJson(const {}).toDomain();

      expect(stats.kpi.todayOrders, 0);
      expect(stats.kpi.todayRevenue, 0.0);
      expect(stats.kpi.pendingOrders, 0);
      expect(stats.kpi.totalCustomers, 0);
      expect(stats.kpi.totalProducts, 0);
      expect(stats.kpi.periodOrders, 0);
      expect(stats.kpi.periodCompletedOrders, 0);
      expect(stats.kpi.periodCancelledOrders, 0);
      expect(stats.kpi.conversionRate, 0.0);

      expect(stats.chartData, isEmpty);
      expect(stats.orderStates, isEmpty);
      expect(stats.recentOrders, isEmpty);

      expect(stats.meta.windowDays, 0);
      expect(stats.meta.refreshIntervalSeconds, 300);
    });

    test('toDomain preserves parsed values (spot-check)', () {
      final stats = DashboardStatsDto.fromJson(sample).toDomain();

      expect(stats, isA<DashboardStats>());
      expect(stats.chartData[0].day, '2026-10-06');
      expect(stats.orderStates[1].status, 'COMPLETED');
      expect(stats.orderStates[1].count, 81);
      expect(stats.recentOrders[0].orderNumber, 'PL-1042');
      expect(stats.meta.windowDays, 7);
    });
  });
}
