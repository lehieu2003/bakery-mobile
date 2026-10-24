import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/product-attributes/domain/models/product_attribute_models.dart';
import 'package:bakery_mobile/src/shared/utils/error_message.dart';

class ProductAttributesAdminState {
  const ProductAttributesAdminState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.isSaving = false,
  });

  final List<AdminCatalogueAttribute> items;
  final bool isLoading;
  final String? error;
  final bool isSaving;

  ProductAttributesAdminState copyWith({
    List<AdminCatalogueAttribute>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isSaving,
  }) {
    return ProductAttributesAdminState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

/// Drives the "Bộ lọc sản phẩm" admin screen: catalogue list + CRUD.
class ProductAttributesAdminViewModel
    extends Notifier<ProductAttributesAdminState> {
  @override
  ProductAttributesAdminState build() => const ProductAttributesAdminState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(productAttributeAdminRepositoryProvider);
    try {
      final items = await repo.getAttributes();
      state = state.copyWith(items: items, isLoading: false);
    } catch (error) {
      if (await _logoutOn401(error)) {
        state = state.copyWith(isLoading: false);
        return;
      }
      state = state.copyWith(isLoading: false, error: _message(error));
    }
  }

  Future<bool> create({
    required String name,
    required String type,
    List<String> valueLabels = const [],
  }) async {
    if (name.trim().isEmpty) {
      state = state.copyWith(error: 'Tên thuộc tính không được để trống');
      return false;
    }
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    final repo = ref.read(productAttributeAdminRepositoryProvider);
    try {
      await repo.createAttribute(
        name: name.trim(),
        type: type,
        valueLabels: valueLabels,
      );
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

  Future<bool> update({
    required String id,
    String? name,
    List<String>? valueLabels,
  }) async {
    if (name != null && name.trim().isEmpty) {
      state = state.copyWith(error: 'Tên thuộc tính không được để trống');
      return false;
    }
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    final repo = ref.read(productAttributeAdminRepositoryProvider);
    try {
      await repo.updateAttribute(
        id: id,
        name: name?.trim(),
        valueLabels: valueLabels,
      );
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

  Future<bool> remove(String id) async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    final repo = ref.read(productAttributeAdminRepositoryProvider);
    try {
      await repo.deleteAttribute(id);
      state = state.copyWith(
        items: state.items.where((a) => a.id != id).toList(),
        isSaving: false,
      );
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

  Future<bool> _logoutOn401(Object error) async {
    if (error is ApiException && error.statusCode == 401) {
      await ref.read(authViewModelProvider.notifier).logout();
      return true;
    }
    return false;
  }

  String _message(Object error) => userErrorMessage(error);
}

final productAttributesAdminViewModelProvider =
    NotifierProvider<
      ProductAttributesAdminViewModel,
      ProductAttributesAdminState
    >(ProductAttributesAdminViewModel.new);
