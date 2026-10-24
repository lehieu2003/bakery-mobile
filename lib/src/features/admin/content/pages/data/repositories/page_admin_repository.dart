import 'package:bakery_mobile/src/features/admin/content/pages/data/datasources/page_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/content/pages/data/dtos/page_admin_dto.dart';
import 'package:bakery_mobile/src/features/admin/content/pages/domain/models/admin_page.dart';

class PageAdminRepository {
  const PageAdminRepository(this._service);

  final PageAdminApiService _service;

  Future<List<AdminPage>> getPages() async {
    final data = await _service.getPages();
    return PageAdminDto.listFrom(data is Map ? data['data'] : data);
  }

  Future<void> createPage(Map<String, dynamic> body) =>
      _service.createPage(body);

  Future<void> updatePage(String id, Map<String, dynamic> body) =>
      _service.updatePage(id, body);

  Future<void> deletePage(String id) => _service.deletePage(id);
}
