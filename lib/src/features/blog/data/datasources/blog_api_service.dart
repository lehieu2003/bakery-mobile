import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/features/blog/data/dtos/blog_dto.dart';

class BlogApiService {
  BlogApiService(this._client);

  final ApiClient _client;

  Future<BlogListResultDto> getPosts({
    int page = 1,
    int limit = 10,
    String? search,
    String? categorySlug,
    String? tagSlug,
  }) async {
    final response = await _client.get(
      '/api/blog/posts',
      query: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (categorySlug != null && categorySlug.isNotEmpty)
          'categorySlug': categorySlug,
        if (tagSlug != null && tagSlug.isNotEmpty) 'tagSlug': tagSlug,
      },
    );

    final data = response as Map<String, dynamic>;
    final pagination = data['pagination'] as Map<String, dynamic>? ?? const {};
    final rawPosts = data['posts'] as List<dynamic>? ?? const [];

    return BlogListResultDto(
      posts: rawPosts
          .whereType<Map<String, dynamic>>()
          .map(BlogPostDto.fromJson)
          .toList(),
      page: pagination['page'] is int
          ? pagination['page'] as int
          : int.tryParse('${pagination['page'] ?? ''}') ?? 1,
      totalPages: pagination['totalPages'] is int
          ? pagination['totalPages'] as int
          : int.tryParse('${pagination['totalPages'] ?? ''}') ?? 1,
    );
  }

  Future<BlogPostDto> getPostBySlug(String slug) async {
    final response = await _client.get('/api/blog/posts/$slug');
    return BlogPostDto.fromJson(response as Map<String, dynamic>);
  }

  Future<List<BlogCategoryDto>> getCategories() async {
    final response = await _client.get('/api/blog/categories');
    final raw =
        (response as Map<String, dynamic>)['categories'] as List<dynamic>? ??
        const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(BlogCategoryDto.fromJson)
        .toList();
  }

  Future<List<BlogTagDto>> getTags() async {
    final response = await _client.get('/api/blog/tags');
    final raw =
        (response as Map<String, dynamic>)['tags'] as List<dynamic>? ??
        const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(BlogTagDto.fromJson)
        .toList();
  }
}
