import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/features/blog/domain/models/blog.dart';

class BlogState {
  const BlogState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.posts = const [],
    this.categories = const [],
    this.tags = const [],
    this.page = 1,
    this.totalPages = 1,
    this.search = '',
    this.categorySlug = '',
    this.tagSlug = '',
  });

  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<BlogPost> posts;
  final List<BlogCategory> categories;
  final List<BlogTag> tags;
  final int page;
  final int totalPages;
  final String search;
  final String categorySlug;
  final String tagSlug;

  bool get hasMore => page < totalPages;

  BlogState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    List<BlogPost>? posts,
    List<BlogCategory>? categories,
    List<BlogTag>? tags,
    int? page,
    int? totalPages,
    String? search,
    String? categorySlug,
    String? tagSlug,
  }) {
    return BlogState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      posts: posts ?? this.posts,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      search: search ?? this.search,
      categorySlug: categorySlug ?? this.categorySlug,
      tagSlug: tagSlug ?? this.tagSlug,
    );
  }
}

class BlogViewModel extends Notifier<BlogState> {
  static const _pageSize = 12;

  @override
  BlogState build() => const BlogState();

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repo = ref.read(blogRepositoryProvider);
      final results = await Future.wait([
        repo.getCategories(),
        repo.getTags(),
        repo.getPosts(page: 1, limit: _pageSize),
      ]);
      final listResult = results[2] as BlogListResult;
      state = state.copyWith(
        isLoading: false,
        categories: results[0] as List<BlogCategory>,
        tags: results[1] as List<BlogTag>,
        posts: listResult.posts,
        page: listResult.page,
        totalPages: listResult.totalPages,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> applyFilter({
    String? search,
    String? categorySlug,
    String? tagSlug,
  }) async {
    state = state.copyWith(
      search: search ?? state.search,
      categorySlug: categorySlug ?? state.categorySlug,
      tagSlug: tagSlug ?? state.tagSlug,
      isLoading: true,
      clearError: true,
    );

    try {
      final result = await ref
          .read(blogRepositoryProvider)
          .getPosts(
            page: 1,
            limit: _pageSize,
            search: state.search.isEmpty ? null : state.search,
            categorySlug: state.categorySlug.isEmpty
                ? null
                : state.categorySlug,
            tagSlug: state.tagSlug.isEmpty ? null : state.tagSlug,
          );
      state = state.copyWith(
        isLoading: false,
        posts: result.posts,
        page: result.page,
        totalPages: result.totalPages,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final result = await ref
          .read(blogRepositoryProvider)
          .getPosts(
            page: nextPage,
            limit: _pageSize,
            search: state.search.isEmpty ? null : state.search,
            categorySlug: state.categorySlug.isEmpty
                ? null
                : state.categorySlug,
            tagSlug: state.tagSlug.isEmpty ? null : state.tagSlug,
          );
      state = state.copyWith(
        isLoadingMore: false,
        page: result.page,
        totalPages: result.totalPages,
        posts: [...state.posts, ...result.posts],
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}
