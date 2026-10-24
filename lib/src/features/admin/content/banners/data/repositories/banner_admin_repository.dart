import 'package:bakery_mobile/src/features/admin/content/banners/data/datasources/banner_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/content/banners/data/dtos/banner_admin_dto.dart';
import 'package:bakery_mobile/src/features/admin/content/banners/domain/models/admin_banner.dart';

class BannerAdminRepository {
  const BannerAdminRepository(this._service);

  final BannerAdminApiService _service;

  Future<List<AdminBanner>> getBanners() async {
    final data = await _service.getBanners();
    return BannerAdminDto.listFrom(data is Map ? data['data'] : data);
  }

  Future<void> createBanner(Map<String, dynamic> body) =>
      _service.createBanner(body);

  Future<void> updateBanner(String id, Map<String, dynamic> body) =>
      _service.updateBanner(id, body);

  Future<void> deleteBanner(String id) => _service.deleteBanner(id);

  Future<void> reorderBanners(List<String> orderedIds) =>
      _service.reorderBanners(orderedIds);
}
