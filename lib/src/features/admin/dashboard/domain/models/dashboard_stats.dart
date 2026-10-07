/// Aggregated admin dashboard statistics for a trailing time window, as
/// exposed by `GET /api/admin/dashboard`. Shape pinned from
/// `bakery-web/types/api.types.ts` (DashboardStats).
class DashboardStats {
  const DashboardStats({
    required this.kpi,
    required this.chartData,
    required this.orderStates,
    required this.recentOrders,
    required this.meta,
  });

  final DashboardKpi kpi;
  final List<DashboardChartPoint> chartData;
  final List<OrderStateCount> orderStates;
  final List<DashboardRecentOrder> recentOrders;
  final DashboardMeta meta;
}

/// Headline counters for the dashboard's KPI cards. Money fields are
/// doubles (VND amounts arrive as numbers or numeric strings).
class DashboardKpi {
  const DashboardKpi({
    required this.todayOrders,
    required this.todayRevenue,
    required this.pendingOrders,
    required this.totalCustomers,
    required this.totalProducts,
    required this.periodOrders,
    required this.periodCompletedOrders,
    required this.periodCancelledOrders,
    required this.conversionRate,
  });

  final int todayOrders;
  final double todayRevenue;
  final int pendingOrders;
  final int totalCustomers;
  final int totalProducts;

  /// Order totals across the whole [DashboardMeta.windowDays] window.
  final int periodOrders;
  final int periodCompletedOrders;
  final int periodCancelledOrders;

  /// Completed-to-placed ratio for the window, in percent.
  final double conversionRate;
}

/// One day of the revenue/orders chart, oldest first.
class DashboardChartPoint {
  const DashboardChartPoint({
    required this.day,
    required this.orders,
    required this.revenue,
    required this.completedOrders,
    required this.cancelledOrders,
  });

  /// ISO date label, e.g. `2026-10-07`.
  final String day;
  final int orders;
  final double revenue;
  final int completedOrders;
  final int cancelledOrders;
}

/// Count of orders grouped by one lifecycle status (e.g. `PENDING`).
class OrderStateCount {
  const OrderStateCount({required this.status, required this.count});

  final String status;
  final int count;
}

/// The newest orders shown in the dashboard's recent-orders list.
class DashboardRecentOrder {
  const DashboardRecentOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.itemsCount,
  });

  final String id;
  final String orderNumber;

  /// Display name of the customer; may be empty for deleted accounts.
  final String customerName;
  final double total;
  final String status;
  final DateTime createdAt;
  final int itemsCount;
}

/// Query window + polling hints the dashboard was computed with.
class DashboardMeta {
  const DashboardMeta({
    required this.windowDays,
    required this.refreshIntervalSeconds,
  });

  final int windowDays;
  final int refreshIntervalSeconds;
}
