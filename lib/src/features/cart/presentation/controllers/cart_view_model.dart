import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/features/cart/domain/models/cart_item.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';

class CartState {
  const CartState({this.items = const []});

  final List<CartItem> items;

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => items.fold(0, (sum, item) => sum + item.lineTotal);

  CartState copyWith({List<CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }
}

class CartViewModel extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void addProduct(Product product, {ProductVariant? variant}) {
    final next = [...state.items];
    final existingIndex = next.indexWhere(
      (item) => item.productId == product.id && item.variantId == variant?.id,
    );

    if (existingIndex >= 0) {
      final current = next[existingIndex];
      next[existingIndex] = current.copyWith(quantity: current.quantity + 1);
    } else {
      next.add(
        CartItem(
          productId: product.id,
          name: product.name,
          price: variant?.price ?? product.price,
          quantity: 1,
          imageUrl: product.thumbnail,
          variantId: variant?.id,
          variantName: variant?.name,
        ),
      );
    }

    state = state.copyWith(items: next);
  }

  void increase(CartItem item) {
    _updateQty(item, item.quantity + 1);
  }

  void decrease(CartItem item) {
    final nextQty = item.quantity - 1;
    if (nextQty <= 0) {
      remove(item);
      return;
    }
    _updateQty(item, nextQty);
  }

  void remove(CartItem item) {
    final next = [...state.items]..remove(item);
    state = state.copyWith(items: next);
  }

  void clear() {
    state = const CartState();
  }

  void _updateQty(CartItem item, int qty) {
    final next = [...state.items];
    final index = next.indexOf(item);
    if (index < 0) return;
    next[index] = item.copyWith(quantity: qty);
    state = state.copyWith(items: next);
  }
}
