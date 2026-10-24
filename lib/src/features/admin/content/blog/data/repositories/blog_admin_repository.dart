import 'package:bakery_mobile/src/features/admin/content/blog/data/datasources/blog_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/content/blog/data/dtos/blog_admin_dto.dart';
import 'package:bakery_mobile/src/features/admin/content/blog/domain/models/blog_models.dart';

class BlogAdminRepository {
  const BlogAdminRepository(this._service);

  final BlogAdminApiService _service;

  Future<BlogPostPage> getPosts({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    // ApiClient already unwraps `{success, data}` — the payload here is
    // `{posts, pagination}`.
    final data = await _service.getPosts(
      page: page,
      limit: limit,
      search: search,
    );
    return BlogPostListDto.fromJson(data);
  }

  Future<void> createPost(Map<String, dynamic> body) =>
      _service.createPost(body);

  Future<void> updatePostStatus(String id, String status) =>
      _service.updatePostStatus(id, status);

  Future<void> deletePost(String id) => _service.deletePost(id);

  Future<List<BlogCategory>> getCategories() async {
    final data = await _service.getCategories();
    return blogCategoryListFrom(data is Map ? data['data'] : data);
  }

  Future<void> createCategory(Map<String, dynamic> body) =>
      _service.createCategory(body);

  Future<void> deleteCategory(String id) => _service.deleteCategory(id);

  Future<List<BlogTag>> getTags() async {
    final data = await _service.getTags();
    return blogTagListFrom(data is Map ? data['data'] : data);
  }

  Future<void> createTag(Map<String, dynamic> body) => _service.createTag(body);

  Future<void> deleteTag(String id) => _service.deleteTag(id);
}
