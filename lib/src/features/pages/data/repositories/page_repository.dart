import 'package:bakery_mobile/src/features/pages/domain/models/app_page.dart';
import 'package:bakery_mobile/src/features/pages/data/datasources/page_api_service.dart';

class PageRepository {
  PageRepository(this._pageApiService);

  final PageApiService _pageApiService;

  Future<List<AppPageSummary>> getPages() => _pageApiService.getPages();

  Future<AppPageDetail> getPageBySlug(String slug) {
    return _pageApiService.getPageBySlug(slug);
  }
}


