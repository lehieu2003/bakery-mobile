import 'package:flutter/foundation.dart';

import 'package:bakery_mobile/src/features/cart/domain/models/cart_item.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';

class CartViewModel extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0, (sum, item) => sum + item.lineTotal);

  void addProduct(Product product, {ProductVariant? variant}) {
    final existingIndex = _items.indexWhere(
      (item) => item.productId == product.id && item.variantId == variant?.id,
    );

    if (existingIndex >= 0) {
      final current = _items[existingIndex];
      _items[existingIndex] = current.copyWith(quantity: current.quantity + 1);
    } else {
      _items.add(
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

    notifyListeners();
  }

  void increase(CartItem item) {
    _updateQty(item, item.quantity + 1);
  }

  void decrease(CartItem item) {
    final next = item.quantity - 1;
    if (next <= 0) {
      remove(item);
      return;
    }
    _updateQty(item, next);
  }

  void remove(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  void _updateQty(CartItem item, int qty) {
    final index = _items.indexOf(item);
    if (index < 0) return;
    _items[index] = item.copyWith(quantity: qty);
    notifyListeners();
  }
}


