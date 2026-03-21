import 'package:flutter/foundation.dart';

import 'package:bakery_mobile/src/features/blog/domain/models/blog.dart';
import 'package:bakery_mobile/src/features/blog/data/repositories/blog_repository.dart';

class BlogViewModel extends ChangeNotifier {
  BlogViewModel(this._blogRepository);

  final BlogRepository _blogRepository;
  static const _pageSize = 12;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  List<BlogPost> _posts = [];
  List<BlogCategory> _categories = [];
  List<BlogTag> _tags = [];
  int _page = 1;
  int _totalPages = 1;

  String _search = '';
  String _categorySlug = '';
  String _tagSlug = '';

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  List<BlogPost> get posts => _posts;
  List<BlogCategory> get categories => _categories;
  List<BlogTag> get tags => _tags;
  String get categorySlug => _categorySlug;
  String get tagSlug => _tagSlug;
  bool get hasMore => _page < _totalPages;

  Future<void> loadInitial() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _blogRepository.getCategories(),
        _blogRepository.getTags(),
        _blogRepository.getPosts(page: 1, limit: _pageSize),
      ]);

      _categories = results[0] as List<BlogCategory>;
      _tags = results[1] as List<BlogTag>;
      final listResult = results[2] as BlogListResult;
      _posts = listResult.posts;
      _page = listResult.page;
      _totalPages = listResult.totalPages;
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> applyFilter({
    String? search,
    String? categorySlug,
    String? tagSlug,
  }) async {
    if (search != null) _search = search;
    if (categorySlug != null) _categorySlug = categorySlug;
    if (tagSlug != null) _tagSlug = tagSlug;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _blogRepository.getPosts(
        page: 1,
        limit: _pageSize,
        search: _search.isEmpty ? null : _search,
        categorySlug: _categorySlug.isEmpty ? null : _categorySlug,
        tagSlug: _tagSlug.isEmpty ? null : _tagSlug,
      );
      _posts = result.posts;
      _page = result.page;
      _totalPages = result.totalPages;
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !hasMore) return;

    _isLoadingMore = true;
    notifyListeners();
    try {
      final nextPage = _page + 1;
      final result = await _blogRepository.getPosts(
        page: nextPage,
        limit: _pageSize,
        search: _search.isEmpty ? null : _search,
        categorySlug: _categorySlug.isEmpty ? null : _categorySlug,
        tagSlug: _tagSlug.isEmpty ? null : _tagSlug,
      );
      _page = result.page;
      _totalPages = result.totalPages;
      _posts = [..._posts, ...result.posts];
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<BlogPost?> loadPost(String slug) async {
    try {
      return await _blogRepository.getPostBySlug(slug);
    } catch (_) {
      return null;
    }
  }
}


