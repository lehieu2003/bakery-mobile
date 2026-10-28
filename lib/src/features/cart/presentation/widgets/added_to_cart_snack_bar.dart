import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/features/cart/presentation/screens/cart_screen.dart';

/// Confirms an add to cart, naming [productName], with a "Xem giỏ" action
/// that opens the cart. Replaces the previous one, so tapping add several
/// times does not queue a line of snack bars.
void showAddedToCartSnackBar(BuildContext context, String productName) {
  // Captured now: the tile that added may be gone when the action is tapped.
  final navigator = Navigator.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          'Đã thêm $productName vào giỏ',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        action: SnackBarAction(
          label: 'Xem giỏ',
          onPressed: () => navigator.push(
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
        ),
      ),
    );
}
