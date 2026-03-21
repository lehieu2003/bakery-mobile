import 'package:bakery_mobile/src/features/blog/domain/models/blog.dart';
import 'package:bakery_mobile/src/features/blog/data/datasources/blog_api_service.dart';

class BlogRepository {
  BlogRepository(this._blogApiService);

  final BlogApiService _blogApiService;

  Future<BlogListResult> getPosts({
    int page = 1,
    int limit = 10,
    String? search,
    String? categorySlug,
    String? tagSlug,
  }) async {
    final result = await _blogApiService.getPosts(
      page: page,
      limit: limit,
      search: search,
      categorySlug: categorySlug,
      tagSlug: tagSlug,
    );
    return BlogListResult(
      posts: result.posts.map((e) => e.toDomain()).toList(),
      page: result.page,
      totalPages: result.totalPages,
    );
  }

  Future<BlogPost> getPostBySlug(String slug) async {
    return (await _blogApiService.getPostBySlug(slug)).toDomain();
  }

  Future<List<BlogCategory>> getCategories() async {
    return (await _blogApiService.getCategories())
        .map((e) => e.toDomain())
        .toList();
  }

  Future<List<BlogTag>> getTags() async {
    return (await _blogApiService.getTags()).map((e) => e.toDomain()).toList();
  }
}
