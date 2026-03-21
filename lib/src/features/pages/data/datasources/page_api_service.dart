import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/features/pages/domain/models/app_page.dart';

class PageApiService {
  PageApiService(this._client);

  final ApiClient _client;

  Future<List<AppPageSummary>> getPages() async {
    final response = await _client.get('/api/public/pages');
    final raw = response as List<dynamic>? ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AppPageSummary.fromJson)
        .toList();
  }

  Future<AppPageDetail> getPageBySlug(String slug) async {
    final response = await _client.get('/api/public/pages/$slug');
    return AppPageDetail.fromJson(response as Map<String, dynamic>);
  }
}


