import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/content/blog/domain/models/blog_models.dart';
import 'package:bakery_mobile/src/shared/utils/error_message.dart';

class BlogPostsAdminState {
  const BlogPostsAdminState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.isSaving = false,
  });

  final List<BlogPost> items;
  final bool isLoading;
  final String? error;
  final bool isSaving;

  BlogPostsAdminState copyWith({
    List<BlogPost>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isSaving,
  }) {
    return BlogPostsAdminState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Blog posts admin: paged list + create (DRAFT) + publish toggle + delete.
class BlogPostsAdminViewModel extends Notifier<BlogPostsAdminState> {
  @override
  BlogPostsAdminState build() => const BlogPostsAdminState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(blogAdminRepositoryProvider);
    try {
      final page = await repo.getPosts();
      state = state.copyWith(items: page.items, isLoading: false);
    } catch (error) {
      if (await _logoutOn401(error)) {
        state = state.copyWith(isLoading: false);
        return;
      }
      state = state.copyWith(isLoading: false, error: _message(error));
    }
  }

  /// Creates a DRAFT post; the web console handles rich editing/publishing.
  Future<bool> create({
    required String title,
    required String content,
    String? excerpt,
    String status = 'DRAFT',
  }) async {
    if (title.trim().isEmpty) {
      state = state.copyWith(error: 'Tiêu đề không được để trống');
      return false;
    }
    if (content.trim().isEmpty) {
      state = state.copyWith(error: 'Nội dung không được để trống');
      return false;
    }
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    final repo = ref.read(blogAdminRepositoryProvider);
    try {
      await repo.createPost({
        'title': title.trim(),
        'content': content.trim(),
        if (excerpt != null && excerpt.trim().isNotEmpty)
          'excerpt': excerpt.trim(),
        'status': status,
      });
      await load();
      state = state.copyWith(isSaving: false);
      return true;
    } catch (error) {
      if (await _logoutOn401(error)) {
        state = state.copyWith(isSaving: false);
        return false;
      }
      state = state.copyWith(isSaving: false, error: _message(error));
      return false;
    }
  }

  /// Publishes or unpublishes via the dedicated `/status` endpoint.
  Future<void> setStatus(String id, String status) async {
    try {
      await ref.read(blogAdminRepositoryProvider).updatePostStatus(id, status);
      await load();
    } catch (error) {
      if (!await _logoutOn401(error)) {
        state = state.copyWith(error: _message(error));
      }
    }
  }

  Future<void> remove(String id) async {
    try {
      await ref.read(blogAdminRepositoryProvider).deletePost(id);
    } catch (error) {
      if (!await _logoutOn401(error)) {
        state = state.copyWith(error: _message(error));
      }
    }
    await load();
  }

  Future<bool> _logoutOn401(Object error) async {
    if (error is ApiException && error.statusCode == 401) {
      await ref.read(authViewModelProvider.notifier).logout();
      return true;
    }
    return false;
  }

  String _message(Object error) => userErrorMessage(error);
}

final blogPostsAdminViewModelProvider =
    NotifierProvider<BlogPostsAdminViewModel, BlogPostsAdminState>(
      BlogPostsAdminViewModel.new,
    );
