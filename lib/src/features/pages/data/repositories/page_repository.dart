import 'package:bakery_mobile/src/features/pages/domain/models/app_page.dart';
import 'package:bakery_mobile/src/features/pages/data/datasources/page_api_service.dart';

class PageRepository {
  PageRepository(this._pageApiService);

  final PageApiService _pageApiService;

  Future<List<AppPageSummary>> getPages() async {
    return (await _pageApiService.getPages()).map((e) => e.toDomain()).toList();
  }

  Future<AppPageDetail> getPageBySlug(String slug) async {
    return (await _pageApiService.getPageBySlug(slug)).toDomain();
  }
}
