import 'package:bakery_mobile/src/features/admin/content/menu/data/datasources/menu_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/content/menu/domain/models/menu_models.dart';

AdminMenuItem menuItemFromJson(Map<String, dynamic> json) => AdminMenuItem(
  id: (json['id'] ?? '').toString(),
  title: (json['title'] ?? '').toString(),
  type: (json['type'] ?? 'LINK').toString(),
  url: json['url']?.toString(),
  displayOrder: json['displayOrder'] is num
      ? (json['displayOrder'] as num).toInt()
      : 0,
  isActive: json['isActive'] == true,
);

class MenuAdminRepository {
  const MenuAdminRepository(this._service);

  final MenuAdminApiService _service;

  Future<List<AdminMenuItem>> getMenu() async {
    final data = await _service.getMenu();
    final rows = data is List<dynamic> ? data : const [];
    return [
      for (final row in rows)
        if (row is Map<String, dynamic>) menuItemFromJson(row),
    ];
  }

  Future<void> createMenuItem(Map<String, dynamic> body) =>
      _service.createMenuItem(body);

  Future<void> updateMenuItem(String id, Map<String, dynamic> body) =>
      _service.updateMenuItem(id, body);

  Future<void> deleteMenuItem(String id) => _service.deleteMenuItem(id);
}
