import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/features/pages/data/dtos/page_dto.dart';

class PageApiService {
  PageApiService(this._client);

  final ApiClient _client;

  Future<List<AppPageSummaryDto>> getPages() async {
    final response = await _client.get('/api/public/pages');
    final raw = response as List<dynamic>? ?? const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AppPageSummaryDto.fromJson)
        .toList();
  }

  Future<AppPageDetailDto> getPageBySlug(String slug) async {
    final response = await _client.get('/api/public/pages/$slug');
    return AppPageDetailDto.fromJson(response as Map<String, dynamic>);
  }
}
