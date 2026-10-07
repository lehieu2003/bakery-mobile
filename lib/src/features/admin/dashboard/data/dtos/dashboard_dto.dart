import 'package:bakery_mobile/src/features/admin/dashboard/domain/models/dashboard_stats.dart';
import 'package:bakery_mobile/src/features/admin/shared/utils/json_num.dart';

/// DTO for the admin dashboard payload returned by `GET /api/admin/dashboard`
/// (after `ApiClient` unwraps `data`):
/// `{ kpi, chartData: [...], orderStates: [...], recentOrders: [...], meta }`.
/// The server may emit numeric fields as JSON numbers or numeric strings, so
/// every number goes through [asNum]; parsing is defensive throughout and
/// missing sections fall back to zeroed/empty defaults.
class DashboardStatsDto {
  const DashboardStatsDto({
    required this.kpi,
    required this.chartData,
    required this.orderStates,
    required this.recentOrders,
    required this.meta,
  });

  final DashboardKpiDto kpi;
  final List<DashboardChartPointDto> chartData;
  final List<OrderStateCountDto> orderStates;
  final List<DashboardRecentOrderDto> recentOrders;
  final DashboardMetaDto meta;

  factory DashboardStatsDto.fromJson(Map<String, dynamic> json) {
    final kpi = json['kpi'];
    final meta = json['meta'];
    return DashboardStatsDto(
      kpi: kpi is Map<String, dynamic>
          ? DashboardKpiDto.fromJson(kpi)
          : const DashboardKpiDto(),
      chartData: parseJsonList(json['chartData'], DashboardChartPointDto.fromJson),
      orderStates: parseJsonList(json['orderStates'], OrderStateCountDto.fromJson),
      recentOrders: parseJsonList(
        json['recentOrders'],
        DashboardRecentOrderDto.fromJson,
      ),
      meta: meta is Map<String, dynamic>
          ? DashboardMetaDto.fromJson(meta)
          : const DashboardMetaDto(),
    );
  }

  DashboardStats toDomain() => DashboardStats(
    kpi: kpi.toDomain(),
    chartData: chartData.map((point) => point.toDomain()).toList(),
    orderStates: orderStates.map((state) => state.toDomain()).toList(),
    recentOrders: recentOrders.map((order) => order.toDomain()).toList(),
    meta: meta.toDomain(),
  );
}

class DashboardKpiDto {
  const DashboardKpiDto({
    this.todayOrders = 0,
    this.todayRevenue = 0.0,
    this.pendingOrders = 0,
    this.totalCustomers = 0,
    this.totalProducts = 0,
    this.periodOrders = 0,
    this.periodCompletedOrders = 0,
    this.periodCancelledOrders = 0,
    this.conversionRate = 0.0,
  });

  final int todayOrders;
  final double todayRevenue;
  final int pendingOrders;
  final int totalCustomers;
  final int totalProducts;
  final int periodOrders;
  final int periodCompletedOrders;
  final int periodCancelledOrders;
  final double conversionRate;

  factory DashboardKpiDto.fromJson(Map<String, dynamic> json) {
    return DashboardKpiDto(
      todayOrders: asNum(json['todayOrders']).toInt(),
      todayRevenue: asNum(json['todayRevenue']).toDouble(),
      pendingOrders: asNum(json['pendingOrders']).toInt(),
      totalCustomers: asNum(json['totalCustomers']).toInt(),
      totalProducts: asNum(json['totalProducts']).toInt(),
      periodOrders: asNum(json['periodOrders']).toInt(),
      periodCompletedOrders: asNum(json['periodCompletedOrders']).toInt(),
      periodCancelledOrders: asNum(json['periodCancelledOrders']).toInt(),
      conversionRate: asNum(json['conversionRate']).toDouble(),
    );
  }

  DashboardKpi toDomain() => DashboardKpi(
    todayOrders: todayOrders,
    todayRevenue: todayRevenue,
    pendingOrders: pendingOrders,
    totalCustomers: totalCustomers,
    totalProducts: totalProducts,
    periodOrders: periodOrders,
    periodCompletedOrders: periodCompletedOrders,
    periodCancelledOrders: periodCancelledOrders,
    conversionRate: conversionRate,
  );
}

class DashboardChartPointDto {
  const DashboardChartPointDto({
    this.day = '',
    this.orders = 0,
    this.revenue = 0.0,
    this.completedOrders = 0,
    this.cancelledOrders = 0,
  });

  final String day;
  final int orders;
  final double revenue;
  final int completedOrders;
  final int cancelledOrders;

  factory DashboardChartPointDto.fromJson(Map<String, dynamic> json) {
    return DashboardChartPointDto(
      day: (json['day'] ?? '').toString(),
      orders: asNum(json['orders']).toInt(),
      revenue: asNum(json['revenue']).toDouble(),
      completedOrders: asNum(json['completedOrders']).toInt(),
      cancelledOrders: asNum(json['cancelledOrders']).toInt(),
    );
  }

  DashboardChartPoint toDomain() => DashboardChartPoint(
    day: day,
    orders: orders,
    revenue: revenue,
    completedOrders: completedOrders,
    cancelledOrders: cancelledOrders,
  );
}

class OrderStateCountDto {
  const OrderStateCountDto({this.status = '', this.count = 0});

  final String status;
  final int count;

  factory OrderStateCountDto.fromJson(Map<String, dynamic> json) {
    return OrderStateCountDto(
      status: (json['status'] ?? '').toString(),
      count: asNum(json['count']).toInt(),
    );
  }

  OrderStateCount toDomain() => OrderStateCount(status: status, count: count);
}

class DashboardRecentOrderDto {
  const DashboardRecentOrderDto({
    this.id = '',
    this.orderNumber = '',
    this.customerName = '',
    this.total = 0.0,
    this.status = '',
    required this.createdAt,
    this.itemsCount = 0,
  });

  final String id;
  final String orderNumber;
  final String customerName;
  final double total;
  final String status;
  final DateTime createdAt;
  final int itemsCount;

  factory DashboardRecentOrderDto.fromJson(Map<String, dynamic> json) {
    return DashboardRecentOrderDto(
      id: (json['id'] ?? '').toString(),
      orderNumber: (json['orderNumber'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      total: asNum(json['total']).toDouble(),
      status: (json['status'] ?? '').toString(),
      createdAt:
          DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
      itemsCount: asNum(json['itemsCount']).toInt(),
    );
  }

  DashboardRecentOrder toDomain() => DashboardRecentOrder(
    id: id,
    orderNumber: orderNumber,
    customerName: customerName,
    total: total,
    status: status,
    createdAt: createdAt,
    itemsCount: itemsCount,
  );
}

class DashboardMetaDto {
  const DashboardMetaDto({
    this.windowDays = 0,
    this.refreshIntervalSeconds = 300,
  });

  final int windowDays;
  final int refreshIntervalSeconds;

  factory DashboardMetaDto.fromJson(Map<String, dynamic> json) {
    return DashboardMetaDto(
      windowDays: asNum(json['windowDays']).toInt(),
      refreshIntervalSeconds: json['refreshIntervalSeconds'] == null
          ? 300
          : asNum(json['refreshIntervalSeconds']).toInt(),
    );
  }

  DashboardMeta toDomain() =>
      DashboardMeta(
        windowDays: windowDays,
        refreshIntervalSeconds: refreshIntervalSeconds,
      );
}
