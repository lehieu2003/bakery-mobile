import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/content/pages/domain/models/admin_page.dart';
import 'package:bakery_mobile/src/shared/utils/error_message.dart';

class PagesAdminState {
  const PagesAdminState({
    this.pages = const [],
    this.isLoading = false,
    this.error,
    this.isSaving = false,
  });

  final List<AdminPage> pages;
  final bool isLoading;
  final String? error;
  final bool isSaving;

  PagesAdminState copyWith({
    List<AdminPage>? pages,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isSaving,
  }) {
    return PagesAdminState(
      pages: pages ?? this.pages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Static pages admin: list, create/edit (slug auto when blank), delete.
class PagesAdminViewModel extends Notifier<PagesAdminState> {
  @override
  PagesAdminState build() => const PagesAdminState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(pageAdminRepositoryProvider);
    try {
      final pages = await repo.getPages();
      state = state.copyWith(pages: pages, isLoading: false);
    } catch (error) {
      if (await _logoutOn401(error)) {
        state = state.copyWith(isLoading: false);
        return;
      }
      state = state.copyWith(isLoading: false, error: _message(error));
    }
  }

  /// Creates (id null — title AND content required) or edits (partial:
  /// only provided keys are sent).
  Future<bool> save({
    String? id,
    String? title,
    String? slug,
    String? content,
    bool? isPublished,
  }) async {
    if (id == null) {
      if (title == null || title.trim().isEmpty) {
        state = state.copyWith(error: 'Tiêu đề không được để trống');
        return false;
      }
      if (content == null || content.trim().isEmpty) {
        state = state.copyWith(error: 'Nội dung không được để trống');
        return false;
      }
    }
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    final repo = ref.read(pageAdminRepositoryProvider);
    final body = <String, dynamic>{
      if (title != null) 'title': title.trim(),
      // verbatim — newlines preserved
      if (content != null) 'content': content,
      if (slug != null && slug.trim().isNotEmpty) 'slug': slug.trim(),
      if (isPublished != null) 'isPublished': isPublished,
    };
    try {
      if (id == null) {
        await repo.createPage(body);
      } else {
        await repo.updatePage(id, body);
      }
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

  Future<void> remove(String id) async {
    try {
      await ref.read(pageAdminRepositoryProvider).deletePage(id);
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

final pagesAdminViewModelProvider =
    NotifierProvider<PagesAdminViewModel, PagesAdminState>(
      PagesAdminViewModel.new,
    );
