import 'package:bakery_mobile/src/features/admin/settings/data/datasources/settings_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/settings/domain/models/settings_models.dart';

class SettingsAdminRepository {
  const SettingsAdminRepository(this._service);

  final SettingsAdminApiService _service;

  Future<AdminSettings> getSettings() async {
    final data = await _service.getSettings();
    return adminSettingsFromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }

  Future<void> putSettings(Map<String, dynamic> body) =>
      _service.putSettings(body);
}
