import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/content/menu/domain/models/menu_models.dart';
import 'package:bakery_mobile/src/shared/utils/error_message.dart';

class MenuAdminState {
  const MenuAdminState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.isSaving = false,
  });

  final List<AdminMenuItem> items;
  final bool isLoading;
  final String? error;
  final bool isSaving;

  MenuAdminState copyWith({
    List<AdminMenuItem>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isSaving,
  }) {
    return MenuAdminState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Header menu items admin (bare-array endpoint; empty is normal).
class MenuAdminViewModel extends Notifier<MenuAdminState> {
  @override
  MenuAdminState build() => const MenuAdminState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(menuAdminRepositoryProvider);
    try {
      final items = await repo.getMenu();
      state = state.copyWith(items: items, isLoading: false);
    } catch (error) {
      if (await _logoutOn401(error)) {
        state = state.copyWith(isLoading: false);
        return;
      }
      state = state.copyWith(isLoading: false, error: _message(error));
    }
  }

  Future<bool> save({
    String? id,
    required String title,
    required String url,
  }) async {
    if (title.trim().isEmpty) {
      state = state.copyWith(error: 'Tiêu đề không được để trống');
      return false;
    }
    if (url.trim().isEmpty) {
      state = state.copyWith(error: 'Liên kết không được để trống');
      return false;
    }
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    final repo = ref.read(menuAdminRepositoryProvider);
    final body = <String, dynamic>{
      'title': title.trim(),
      'type': 'LINK',
      'url': url.trim(),
      'isActive': true,
    };
    try {
      if (id == null) {
        await repo.createMenuItem(body);
      } else {
        await repo.updateMenuItem(id, body);
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
      await ref.read(menuAdminRepositoryProvider).deleteMenuItem(id);
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

final menuAdminViewModelProvider =
    NotifierProvider<MenuAdminViewModel, MenuAdminState>(
      MenuAdminViewModel.new,
    );
