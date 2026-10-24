import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/content/banners/domain/models/admin_banner.dart';
import 'package:bakery_mobile/src/shared/utils/error_message.dart';

class BannersAdminState {
  const BannersAdminState({
    this.banners = const [],
    this.isLoading = false,
    this.error,
    this.isSaving = false,
  });

  final List<AdminBanner> banners;
  final bool isLoading;
  final String? error;
  final bool isSaving;

  BannersAdminState copyWith({
    List<AdminBanner>? banners,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isSaving,
  }) {
    return BannersAdminState(
      banners: banners ?? this.banners,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Drives the Banner admin screen: ordered list, create/edit, delete and
/// same-list reorder (up/down) — mirror of the categories VM.
class BannersAdminViewModel extends Notifier<BannersAdminState> {
  @override
  BannersAdminState build() => const BannersAdminState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(bannerAdminRepositoryProvider);
    try {
      final banners = await repo.getBanners();
      state = state.copyWith(banners: banners, isLoading: false);
    } catch (error) {
      if (await _logoutOn401(error)) {
        state = state.copyWith(isLoading: false);
        return;
      }
      state = state.copyWith(isLoading: false, error: _message(error));
    }
  }

  /// Creates (no [id]) or edits (with [id]); only provided keys are sent.
  /// Returns true on success — caller reloads via [load].
  Future<bool> save({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? linkUrl,
    bool? isActive,
    int? displayOrder,
  }) async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    final repo = ref.read(bannerAdminRepositoryProvider);
    final body = <String, dynamic>{
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (linkUrl != null) 'linkUrl': linkUrl,
      if (isActive != null) 'isActive': isActive,
      if (displayOrder != null) 'displayOrder': displayOrder,
    };
    try {
      if (id == null) {
        await repo.createBanner(body);
      } else {
        await repo.updateBanner(id, body);
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

  /// Moves the banner at [index] up/down within the display order, sends
  /// the new order to the server, then reloads.
  Future<void> move(int index, {required bool up}) async {
    final banners = [...state.banners];
    final target = up ? index - 1 : index + 1;
    if (target < 0 || target >= banners.length) return;
    final swapped = banners[index];
    banners[index] = banners[target];
    banners[target] = swapped;
    state = state.copyWith(banners: banners);
    try {
      await ref
          .read(bannerAdminRepositoryProvider)
          .reorderBanners(banners.map((b) => b.id).toList());
    } catch (error) {
      if (!await _logoutOn401(error)) {
        state = state.copyWith(error: _message(error));
      }
    }
    await load();
  }

  Future<void> remove(String id) async {
    try {
      await ref.read(bannerAdminRepositoryProvider).deleteBanner(id);
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

final bannersAdminViewModelProvider =
    NotifierProvider<BannersAdminViewModel, BannersAdminState>(
      BannersAdminViewModel.new,
    );
