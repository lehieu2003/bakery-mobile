import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';
import 'package:bakery_mobile/src/features/wishlist/domain/models/wishlist_item.dart';

class WishlistState {
  const WishlistState({
    this.isLoading = false,
    this.error,
    this.items = const [],
    this.pendingProductIds = const <String>{},
  });

  final bool isLoading;
  final String? error;
  final List<WishlistItem> items;
  final Set<String> pendingProductIds;

  bool isFavorite(String productId) =>
      items.any((item) => item.productId == productId);

  bool isPending(String productId) => pendingProductIds.contains(productId);

  WishlistState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<WishlistItem>? items,
    Set<String>? pendingProductIds,
  }) {
    return WishlistState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      items: items ?? this.items,
      pendingProductIds: pendingProductIds ?? this.pendingProductIds,
    );
  }
}

class WishlistViewModel extends Notifier<WishlistState> {
  @override
  WishlistState build() => const WishlistState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await ref.read(wishlistRepositoryProvider).getWishlist();
      state = state.copyWith(isLoading: false, items: items);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> toggle(Product product) async {
    if (state.isPending(product.id)) return;

    final pending = <String>{...state.pendingProductIds, product.id};
    state = state.copyWith(pendingProductIds: pending);

    final wasFavorite = state.isFavorite(product.id);
    final previousItems = state.items;
    final now = DateTime.now();

    if (wasFavorite) {
      state = state.copyWith(
        items: previousItems
            .where((item) => item.productId != product.id)
            .toList(),
      );
    } else {
      state = state.copyWith(
        items: [
          WishlistItem(
            id: 'optimistic-${product.id}',
            userId: '',
            productId: product.id,
            createdAt: now,
            product: product,
          ),
          ...previousItems,
        ],
      );
    }

    try {
      if (wasFavorite) {
        await ref
            .read(wishlistRepositoryProvider)
            .removeFromWishlist(product.id);
      } else {
        final item = await ref
            .read(wishlistRepositoryProvider)
            .addToWishlist(product.id);

        state = state.copyWith(
          items: [
            item,
            ...state.items.where((entry) => entry.productId != product.id),
          ],
        );
      }
    } catch (error) {
      state = state.copyWith(
        items: previousItems,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      final nextPending = <String>{...state.pendingProductIds}
        ..remove(product.id);
      state = state.copyWith(pendingProductIds: nextPending);
    }
  }
}
