import 'package:bakery_mobile/src/features/admin/dashboard/data/datasources/dashboard_api_service.dart';
import 'package:bakery_mobile/src/features/admin/dashboard/data/dtos/dashboard_dto.dart';
import 'package:bakery_mobile/src/features/admin/dashboard/domain/models/dashboard_stats.dart';

class DashboardRepository {
  const DashboardRepository(this._service);

  final DashboardApiService _service;

  /// Loads the admin dashboard stats for the trailing [windowDays] days.
  Future<DashboardStats> getStats({int windowDays = 7}) async {
    final payload = await _service.getDashboard(windowDays: windowDays);
    return DashboardStatsDto.fromJson(payload).toDomain();
  }
}
