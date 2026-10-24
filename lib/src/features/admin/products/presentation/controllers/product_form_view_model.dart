import 'dart:convert' show base64Encode;
import 'dart:io' show File;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/products/domain/models/admin_product.dart';
import 'package:bakery_mobile/src/shared/utils/error_message.dart';

/// One gallery entry: a hosted url (edit preload) or a freshly picked
/// local file awaiting upload at save time (deferred, parity with web).
class FormImage {
  const FormImage({
    required this.source,
    this.isPrimary = false,
    this.isLocal = false,
  });

  /// Hosted url or local file path.
  final String source;
  final bool isPrimary;
  final bool isLocal;
}

/// One dynamic variant row being edited.
class FormVariant {
  const FormVariant({
    required this.key,
    this.id,
    this.name = '',
    this.sku = '',
    this.priceText = '',
    this.stockText = '',
  });

  /// Local identity for widget keys (server id only exists after save).
  final int key;
  final String? id;
  final String name;
  final String sku;
  final String priceText;
  final String stockText;
}

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
    this.images = const [],
    this.variants = const [],
    this.assignments = const {},
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

  final List<FormImage> images;
  final List<FormVariant> variants;

  /// attributeId → picked valueIds (SELECT keeps ≤1, MULTI any).
  final Map<String, List<String>> assignments;

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
    List<FormImage>? images,
    List<FormVariant>? variants,
    Map<String, List<String>>? assignments,
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
      images: images ?? this.images,
      variants: variants ?? this.variants,
      assignments: assignments ?? this.assignments,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  /// Wire shape for POST/PUT: only attributes with at least one pick.
  List<AdminProductDetailAssignment> buildAssignments() {
    return [
      for (final entry in assignments.entries)
        if (entry.value.isNotEmpty)
          AdminProductDetailAssignment(
            attributeId: entry.key,
            valueIds: entry.value,
          ),
    ];
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
class ProductFormViewModel extends FamilyNotifier<ProductFormState, String?> {
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
        comparePriceText: detail.comparePrice == null
            ? ''
            : _plain(detail.comparePrice!),
        shortDescription: detail.shortDescription ?? '',
        description: detail.description ?? '',
        isActive: detail.isActive,
        categoryId: detail.categoryIds.isEmpty
            ? null
            : detail.categoryIds.first,
        images: [
          for (final image in detail.images)
            FormImage(
              source: image.url,
              isPrimary: image.isPrimary,
              isLocal: false,
            ),
        ],
        variants: [
          for (var i = 0; i < detail.variants.length; i++)
            FormVariant(
              key: i,
              id: detail.variants[i].id,
              name: detail.variants[i].name,
              sku: detail.variants[i].sku ?? '',
              priceText: _plain(detail.variants[i].price),
              stockText: '${detail.variants[i].stock}',
            ),
        ],
        assignments: {
          for (final assignment in detail.assignments)
            if (assignment.valueIds.isNotEmpty)
              assignment.attributeId: assignment.valueIds,
        },
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

  /// Appends freshly picked local files (deferred upload). The gallery
  /// holds at most 10 entries; extras are dropped. The first entry without
  /// any primary becomes primary.
  void addLocalImages(List<String> paths) {
    final updated = [...state.images];
    for (final path in paths) {
      if (updated.length >= 10) break;
      updated.add(FormImage(source: path, isLocal: true));
    }
    state = state.copyWith(images: _withOnePrimary(updated));
  }

  /// Marks [index] as the single primary image.
  void setPrimary(int index) {
    final updated = [
      for (var i = 0; i < state.images.length; i++)
        FormImage(
          source: state.images[i].source,
          isPrimary: i == index,
          isLocal: state.images[i].isLocal,
        ),
    ];
    state = state.copyWith(images: updated);
  }

  /// Removes one gallery entry; when the primary was removed the first
  /// remaining entry takes over.
  void removeImage(int index) {
    final updated = [...state.images]..removeAt(index);
    state = state.copyWith(images: _withOnePrimary(updated));
  }

  List<FormImage> _withOnePrimary(List<FormImage> images) {
    if (images.isEmpty) return images;
    final hasPrimary = images.any((image) => image.isPrimary);
    return [
      for (var i = 0; i < images.length; i++)
        FormImage(
          source: images[i].source,
          isPrimary: !hasPrimary && i == 0 ? true : images[i].isPrimary,
          isLocal: images[i].isLocal,
        ),
    ];
  }

  /// Appends an empty variant row.
  void addVariant() {
    final nextKey = state.variants.isEmpty
        ? 0
        : state.variants.map((v) => v.key).reduce((a, b) => a > b ? a : b) + 1;
    state = state.copyWith(
      variants: [
        ...state.variants,
        FormVariant(key: nextKey),
      ],
    );
  }

  void removeVariant(int index) {
    final updated = [...state.variants]..removeAt(index);
    state = state.copyWith(variants: updated);
  }

  void updateVariant(
    int index, {
    String? name,
    String? sku,
    String? priceText,
    String? stockText,
  }) {
    final row = state.variants[index];
    final updated = [...state.variants];
    updated[index] = FormVariant(
      key: row.key,
      id: row.id,
      name: name ?? row.name,
      sku: sku ?? row.sku,
      priceText: priceText ?? row.priceText,
      stockText: stockText ?? row.stockText,
    );
    state = state.copyWith(variants: updated);
  }

  /// Toggles one attribute value. SELECT attributes keep at most one pick
  /// (a new pick replaces the old); MULTI_SELECT toggles membership.
  void setAssignmentValue(
    String attributeId,
    String valueId,
    bool selected, {
    required bool isMulti,
  }) {
    final current = [...(state.assignments[attributeId] ?? const <String>[])];
    List<String> next;
    if (isMulti) {
      next = selected
          ? <String>{...current, valueId}.toList()
          : current.where((v) => v != valueId).toList();
    } else {
      next = selected ? [valueId] : const [];
    }
    final map = {...state.assignments};
    if (next.isEmpty) {
      map.remove(attributeId);
    } else {
      map[attributeId] = next;
    }
    state = state.copyWith(assignments: map);
  }

  /// Validates, uploads new local images (deferred until now), then
  /// creates or updates the product. Returns true on success — the screen
  /// pops back to the list and triggers a reload.
  Future<bool> save() async {
    if (state.isSaving) return false;
    final problem = state.validate();
    if (problem != null) {
      state = state.copyWith(error: problem);
      return false;
    }
    state = state.copyWith(isSaving: true, clearError: true);

    // Deferred upload: local picks become hosted urls; existing server
    // images pass through untouched.
    List<String> hostedUrls;
    try {
      final locals = state.images.where((image) => image.isLocal).toList();
      hostedUrls = locals.isEmpty
          ? const []
          : await ref.read(uploadApiServiceProvider).uploadImages([
              for (final local in locals) _dataUrlFor(local.source),
            ]);
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        error: 'Tải ảnh lên thất bại — kiểm tra ảnh rồi thử lại',
      );
      return false;
    }

    final uploadedIterator = hostedUrls.iterator;
    final images = <Map<String, dynamic>>[
      for (final image in state.images)
        if (!image.isLocal)
          {'url': image.source, 'isPrimary': image.isPrimary}
        else if (uploadedIterator.moveNext())
          {'url': uploadedIterator.current, 'isPrimary': image.isPrimary},
    ];
    if (images.isNotEmpty && !images.any((i) => i['isPrimary'] == true)) {
      images.first['isPrimary'] = true;
    }

    final body = <String, dynamic>{
      'name': state.name.trim(),
      'price': int.parse(state.priceText.trim()),
      'stock': int.parse(state.stockText.trim()),
      'isActive': state.isActive,
      if (state.slug.trim().isNotEmpty) 'slug': state.slug.trim(),
      if (state.comparePriceText.trim().isNotEmpty)
        'comparePrice': int.parse(state.comparePriceText.trim()),
      if (state.shortDescription.trim().isNotEmpty)
        'shortDescription': state.shortDescription.trim(),
      if (state.description.trim().isNotEmpty)
        'description': state.description.trim(),
      if (state.categoryId != null) 'categoryIds': [state.categoryId],
      'images': images,
      'variants': [
        for (final variant in state.variants)
          if (variant.name.trim().isNotEmpty)
            {
              if (variant.id != null) 'id': variant.id,
              'name': variant.name.trim(),
              if (variant.sku.trim().isNotEmpty) 'sku': variant.sku.trim(),
              'price': int.tryParse(variant.priceText.trim()) ?? 0,
              'stock': int.tryParse(variant.stockText.trim()) ?? 0,
            },
      ],
      'attributeAssignments': [
        for (final assignment in state.buildAssignments())
          {
            'attributeId': assignment.attributeId,
            'valueIds': assignment.valueIds,
          },
      ],
    };

    final repo = ref.read(productsAdminRepositoryProvider);
    try {
      final id = arg;
      if (id == null) {
        await repo.createProduct(body);
      } else {
        await repo.updateProduct(id, body);
      }
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

  /// Reads a local pick into a base64 data URL for `/api/upload`.
  String _dataUrlFor(String path) {
    final bytes = File(path).readAsBytesSync();
    return 'data:${_mimeFor(path)};base64,${base64Encode(bytes)}';
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

String _plain(double value) {
  final i = value.round();
  return i == value ? '$i' : value.toString();
}

/// Lives next to its VM (same convention as the customers feature).
final productFormViewModelProvider =
    NotifierProvider.family<ProductFormViewModel, ProductFormState, String?>(
      ProductFormViewModel.new,
    );

String _mimeFor(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.heic')) return 'image/heic';
  if (lower.endsWith('.avif')) return 'image/avif';
  return 'image/jpeg';
}
