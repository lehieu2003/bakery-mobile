import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/products/domain/models/admin_product.dart';
import 'package:bakery_mobile/src/shared/utils/error_message.dart';

/// Editable state of the product form. Phase 4b adds sections in stages:
/// T2 owns the info block (name/slug/price/stock/compare/descriptions/
/// isActive/category), T3 images, T4 variants + attribute assignments.
class ProductFormState {
  const ProductFormState({
    this.isLoading = false,
    this.error,
    this.detail,
    this.name = '',
    this.slug = '',
    this.priceText = '',
    this.stockText = '',
    this.comparePriceText = '',
    this.shortDescription = '',
    this.description = '',
    this.isActive = true,
    this.categoryId,
    this.isSaving = false,
  });

  final bool isLoading;
  final String? error;

  /// Null in create mode; set once the edit preload lands.
  final AdminProductDetail? detail;

  final String name;
  final String slug;

  /// Plain digit strings (no thousand separators) — the UI formats for
  /// display only; the wire wants numbers.
  final String priceText;
  final String stockText;
  final String comparePriceText;

  final String shortDescription;
  final String description;
  final bool isActive;

  /// Single category pick (the server stores an m2m array — the form sends
  /// `[categoryId]`).
  final String? categoryId;

  final bool isSaving;

  ProductFormState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    AdminProductDetail? detail,
    String? name,
    String? slug,
    String? priceText,
    String? stockText,
    String? comparePriceText,
    String? shortDescription,
    String? description,
    bool? isActive,
    String? categoryId,
    bool clearCategory = false,
    bool? isSaving,
  }) {
    return ProductFormState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      detail: detail ?? this.detail,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      priceText: priceText ?? this.priceText,
      stockText: stockText ?? this.stockText,
      comparePriceText: comparePriceText ?? this.comparePriceText,
      shortDescription: shortDescription ?? this.shortDescription,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      isSaving: isSaving ?? this.isSaving,
    );
  }

  /// First validation problem, or null when the info block is submittable.
  String? validate() {
    if (name.trim().isEmpty) return 'Tên sản phẩm không được để trống';
    if (_parseInt(priceText) == null || _parseInt(priceText)! < 0) {
      return 'Giá sản phẩm phải là số nguyên không âm';
    }
    if (stockText.trim().isEmpty || _parseInt(stockText) == null) {
      return 'Tồn kho phải là số nguyên không âm';
    }
    if (comparePriceText.trim().isNotEmpty &&
        (_parseInt(comparePriceText) == null ||
            _parseInt(comparePriceText)! < 0)) {
      return 'Giá so sánh phải là số nguyên không âm khi có nhập';
    }
    return null;
  }
}

int? _parseInt(String raw) => int.tryParse(raw.trim());

/// Drives the product form. Family key = productId (null = create).
class ProductFormViewModel
    extends FamilyNotifier<ProductFormState, String?> {
  @override
  ProductFormState build(String? arg) => const ProductFormState();

  /// Edit mode: preloads every field from the server's detail.
  Future<void> load() async {
    final id = arg;
    if (id == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(productsAdminRepositoryProvider);
    try {
      final detail = await repo.getProduct(id);
      state = state.copyWith(
        detail: detail,
        isLoading: false,
        name: detail.name,
        slug: detail.slug,
        priceText: _plain(detail.price),
        stockText: '${detail.stock}',
        comparePriceText:
            detail.comparePrice == null ? '' : _plain(detail.comparePrice!),
        shortDescription: detail.shortDescription ?? '',
        description: detail.description ?? '',
        isActive: detail.isActive,
        categoryId: detail.categoryIds.isEmpty ? null : detail.categoryIds.first,
      );
    } catch (error) {
      if (await _logoutOn401(error)) {
        state = state.copyWith(isLoading: false);
        return;
      }
      state = state.copyWith(isLoading: false, error: _message(error));
    }
  }

  void setName(String v) => state = state.copyWith(name: v);
  void setSlug(String v) => state = state.copyWith(slug: v);
  void setPriceText(String v) => state = state.copyWith(priceText: v);
  void setStockText(String v) => state = state.copyWith(stockText: v);
  void setComparePriceText(String v) =>
      state = state.copyWith(comparePriceText: v);
  void setShortDescription(String v) =>
      state = state.copyWith(shortDescription: v);
  void setDescription(String v) => state = state.copyWith(description: v);
  void setIsActive(bool v) => state = state.copyWith(isActive: v);
  void setCategory(String? id) =>
      state = state.copyWith(categoryId: id, clearCategory: id == null);

  Future<bool> _logoutOn401(Object error) async {
    if (error is ApiException && error.statusCode == 401) {
      await ref.read(authViewModelProvider.notifier).logout();
      return true;
    }
    return false;
  }

  String _message(Object error) => userErrorMessage(error);
}

String _plain(double value) {
  final i = value.round();
  return i == value ? '$i' : value.toString();
}

/// Lives next to its VM (same convention as the customers feature).
final productFormViewModelProvider =
    NotifierProvider.family<ProductFormViewModel, ProductFormState, String?>(
      ProductFormViewModel.new,
    );
