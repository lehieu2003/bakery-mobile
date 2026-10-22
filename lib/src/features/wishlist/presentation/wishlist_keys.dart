import 'package:flutter/widgets.dart';

/// Widget keys of the wishlist screen (used by tests and finders).
abstract final class WishlistKeys {
  static const loading = Key('wishlist.loading');
  static const list = Key('wishlist.list');
  static const empty = Key('wishlist.empty');
  static const error = Key('wishlist.error');
  static const errorBanner = Key('wishlist.errorBanner');

  static Key item(String productId) => Key('wishlist.item.$productId');
  static Key toggle(String productId) => Key('wishlist.toggle.$productId');
}
