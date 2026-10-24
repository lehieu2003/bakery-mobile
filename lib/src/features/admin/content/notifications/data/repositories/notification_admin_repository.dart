import 'package:bakery_mobile/src/features/admin/content/notifications/data/datasources/notification_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/content/notifications/data/dtos/notification_admin_dto.dart';

class NotificationAdminRepository {
  const NotificationAdminRepository(this._service);

  final NotificationAdminApiService _service;

  Future<NotificationAdminPage> getNotifications({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final response = await _service.getNotifications(
      page: page,
      limit: limit,
      search: search,
      status: status,
    );
    // ApiClient already unwraps `{success, data}` — the payload here is
    // `{notifications, pagination}`.
    return NotificationAdminListDto.fromJson(response);
  }

  Future<void> createNotification(Map<String, dynamic> body) =>
      _service.createNotification(body);
}
