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
  }) {
    return _blogApiService.getPosts(
      page: page,
      limit: limit,
      search: search,
      categorySlug: categorySlug,
      tagSlug: tagSlug,
    );
  }

  Future<BlogPost> getPostBySlug(String slug) {
    return _blogApiService.getPostBySlug(slug);
  }

  Future<List<BlogCategory>> getCategories() {
    return _blogApiService.getCategories();
  }

  Future<List<BlogTag>> getTags() {
    return _blogApiService.getTags();
  }
}


