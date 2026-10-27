// End-to-end tests per customer feature, on a real emulator against a running
// bakery-web (the API URL comes from the dart-define config, e.g. port 3000
// in config/dev.json):
//
//   fvm flutter test integration_test/app_e2e_test.dart -d emulator-5554 \
//     --flavor dev --dart-define-from-file=config/dev.json
//
// Default run is read-only towards the server: anything it changes is undone
// in the same test (wishlist toggled back, cart item removed). Steps that
// create real data — saving an address, placing an order — only run with:
//
//   --dart-define=E2E_WRITE=true
//
// Each testWidgets mounts the app afresh; the session persists between them
// through secure storage, so the first test logs in and the last logs out.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:bakery_mobile/main.dart';
import 'package:bakery_mobile/src/features/addresses/presentation/screens/addresses_screen.dart';
import 'package:bakery_mobile/src/features/admin/shell/presentation/screens/admin_shell.dart';
import 'package:bakery_mobile/src/features/blog/presentation/screens/blog_detail_screen.dart';
import 'package:bakery_mobile/src/features/blog/presentation/screens/blog_screen.dart';
import 'package:bakery_mobile/src/features/blog/presentation/widgets/blog_post_card.dart';
import 'package:bakery_mobile/src/features/cart/presentation/screens/cart_screen.dart';
import 'package:bakery_mobile/src/features/cart/presentation/screens/checkout_screen.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/home_screen.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/product_detail_screen.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/search_screen.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/widgets/search_product_tile.dart';
import 'package:bakery_mobile/src/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:bakery_mobile/src/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:bakery_mobile/src/features/pages/presentation/screens/page_detail_screen.dart';
import 'package:bakery_mobile/src/features/pages/presentation/screens/pages_screen.dart';
import 'package:bakery_mobile/src/features/profile/presentation/screens/profile_screen.dart';
import 'package:bakery_mobile/src/features/wishlist/presentation/screens/wishlist_screen.dart';
import 'package:bakery_mobile/src/shared/widgets/favorite_icon_widget.dart';

const _email = 'linh@email.com';
const _password = 'admin123';
const _productQuery = 'Tiramisu';
const _write = bool.fromEnvironment('E2E_WRITE');
const _timeout = Timeout(Duration(minutes: 4));

// ───────────────────────────── helpers ─────────────────────────────

/// Lets real network/timers run (pumpAndSettle would hang on spinners).
Future<void> _settle(WidgetTester tester, [int ms = 800]) async {
  await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
  await tester.pump();
}

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump();
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
  }
  final visible = find
      .byType(Text)
      .evaluate()
      .map((e) {
        final w = e.widget as Text;
        return w.data ?? w.textSpan?.toPlainText() ?? '';
      })
      .where((t) => t.trim().isNotEmpty)
      .take(40)
      .join(' | ');
  throw TestFailure('Timed out waiting for $finder\nOn screen: [$visible]');
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await _waitFor(tester, finder);
  await tester.ensureVisible(finder.first);
  await tester.pump();
  await tester.tap(finder.first);
  await _settle(tester);
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    // The target screen's list can still be mounting when we get here.
    try {
      await _waitFor(tester, find.byType(Scrollable));
      await tester.scrollUntilVisible(
        finder,
        300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 60,
      );
    } catch (e) {
      final visible = find
          .byType(Text)
          .evaluate()
          .map((e) {
            final w = e.widget as Text;
            return w.data ?? w.textSpan?.toPlainText() ?? '';
          })
          .where((t) => t.trim().isNotEmpty)
          .take(40)
          .join(' | ');
      throw TestFailure('scrollTo($finder) failed. On screen: [$visible]');
    }
  }
  await tester.ensureVisible(finder.first);
  await tester.pump();
}

/// System back (Android back button): works on screens without an AppBar
/// back button too, e.g. the product page's overlaid arrow.
Future<void> _back(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await _settle(tester);
}

/// Mounts the app; passes onboarding and logs in when needed; ends on home.
Future<void> _launch(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: BakeryMobileApp()));
  final home = find.byType(HomeScreen);
  final email = find.widgetWithText(TextField, 'Email');
  final end = DateTime.now().add(const Duration(seconds: 40));
  while (DateTime.now().isBefore(end)) {
    await _settle(tester, 400);
    if (home.evaluate().isNotEmpty) return;
    // A previous session (e.g. an admin) is still signed in: sign it out so
    // the run always uses the customer account.
    if (find.byType(AdminShell).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('admin_shell_avatar')));
      await _settle(tester);
      await tester.tap(find.text('Đăng xuất').last);
      await _settle(tester, 1500);
      continue;
    }
    final skip = find.text('Bỏ qua');
    if (skip.evaluate().isNotEmpty) {
      await tester.tap(skip.first);
      continue;
    }
    if (email.evaluate().isNotEmpty) {
      await tester.enterText(email.first, _email);
      await tester.enterText(
        find.widgetWithText(TextField, 'Mật khẩu').first,
        _password,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập').first);
      await _waitFor(tester, home);
      return;
    }
  }
  await _waitFor(tester, home);
}

Future<void> _openProfileItem(WidgetTester tester, String title) async {
  await _tap(tester, find.byIcon(Icons.person_outline));
  await _waitFor(tester, find.byType(ProfileScreen));
  await _scrollTo(tester, find.text(title));
  await _tap(tester, find.text(title));
}

Future<void> _openProduct(WidgetTester tester) async {
  await _tap(tester, find.byIcon(Icons.search_outlined));
  await _waitFor(tester, find.byType(SearchScreen));
  final field = find.descendant(
    of: find.byType(SearchScreen),
    matching: find.byType(TextField),
  );
  await tester.enterText(field.first, _productQuery);
  await _waitFor(tester, find.byType(SearchProductTile));
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await _tap(
    tester,
    find.descendant(
      of: find.byType(SearchProductTile),
      matching: find.text(_productQuery),
    ),
  );
  await _waitFor(tester, find.byType(ProductDetailScreen));
}

Finder _pdpFavorite() => find.descendant(
  of: find.byType(ProductDetailScreen),
  matching: find.byType(FavoriteIconWidget),
);

/// Reads the favorite state tolerantly: the icon briefly leaves the tree or
/// flips to its pending style while the wishlist API round-trips.
Future<bool> _readFavorite(WidgetTester tester) async {
  final end = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(end)) {
    await _settle(tester, 200);
    if (_pdpFavorite().evaluate().isNotEmpty) {
      final w = tester.widget<FavoriteIconWidget>(_pdpFavorite().first);
      if (!w.isPending) return w.isFavorite;
    }
  }
  throw TestFailure('Favorite icon never became readable');
}

Future<void> _toggleFavoriteAndWait(WidgetTester tester) async {
  final before = await _readFavorite(tester);
  await _tap(
    tester,
    find.ancestor(of: _pdpFavorite().first, matching: find.byType(IconButton)),
  );
  final end = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(end)) {
    await _settle(tester, 300);
    if (_pdpFavorite().evaluate().isNotEmpty) {
      final w = tester.widget<FavoriteIconWidget>(_pdpFavorite().first);
      if (!w.isPending && w.isFavorite != before) return;
    }
  }
  throw TestFailure('Favorite did not toggle from $before');
}

// ───────────────────────────── tests ─────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy =
      LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('01 auth: onboarding/login lands on home', (tester) async {
    await _launch(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
  }, timeout: _timeout);

  testWidgets('02 home: categories and products load from the API', (
    tester,
  ) async {
    await _launch(tester);
    await _waitFor(tester, find.text('Danh Mục Sản Phẩm'));
    await _waitFor(tester, find.textContaining('₫'));
  }, timeout: _timeout);

  testWidgets('03 search → product detail with reviews', (tester) async {
    await _launch(tester);
    await _openProduct(tester);
    // Wait (not expect): the CTA renders after the product-detail fetch
    // resolves, and a timeout dumps the on-screen texts for debugging.
    await _waitFor(tester, find.text('Thêm vào giỏ'));
    await _scrollTo(tester, find.text('Viết đánh giá'));
  }, timeout: _timeout);

  testWidgets('04 reviews: write-review form opens (not submitted)', (
    tester,
  ) async {
    await _launch(tester);
    await _openProduct(tester);
    await _scrollTo(tester, find.text('Viết đánh giá'));
    await _tap(tester, find.text('Viết đánh giá'));
    await _waitFor(
      tester,
      find.text('Chia sẻ cảm nhận của bạn về sản phẩm...'),
    );
    await _waitFor(tester, find.text('Gửi đánh giá'));
    Navigator.of(tester.element(find.text('Gửi đánh giá'))).pop();
    await _settle(tester);
  }, timeout: _timeout);

  testWidgets('05 wishlist: toggle on PDP, list shows it, restored', (
    tester,
  ) async {
    await _launch(tester);
    await _openProduct(tester);
    // Same race as test 03: wait for the CTA before reading favorite state.
    await _waitFor(tester, find.text('Thêm vào giỏ'));
    final initial = await _readFavorite(tester);
    await _toggleFavoriteAndWait(tester);
    // Whichever state it is in now, make sure it is a favorite for the check.
    if (!await _readFavorite(tester)) await _toggleFavoriteAndWait(tester);

    await _back(tester); // PDP → search
    await _tap(tester, find.byIcon(Icons.home_outlined));
    await _tap(tester, find.byIcon(Icons.favorite_border_rounded));
    await _waitFor(tester, find.byType(WishlistScreen));
    await _waitFor(
      tester,
      find.descendant(
        of: find.byType(WishlistScreen),
        matching: find.text(_productQuery),
      ),
    );
    await _back(tester);

    // Restore the original state.
    await _openProduct(tester);
    await _waitFor(tester, find.text('Thêm vào giỏ'));
    if (await _readFavorite(tester) != initial) {
      await _toggleFavoriteAndWait(tester);
    }
    expect(await _readFavorite(tester), initial);
  }, timeout: _timeout);

  testWidgets('06 cart: add, change quantity, checkout screen, remove', (
    tester,
  ) async {
    await _launch(tester);
    await _openProduct(tester);
    await _tap(tester, find.text('Thêm vào giỏ'));
    await _back(tester);
    await _tap(tester, find.byIcon(Icons.home_outlined));
    await _tap(tester, find.byIcon(Icons.shopping_cart_outlined));
    await _waitFor(tester, find.byType(CartScreen));
    final cart = find.byType(CartScreen);
    await _waitFor(
      tester,
      find.descendant(of: cart, matching: find.text(_productQuery)),
    );

    await _tap(
      tester,
      find.descendant(of: cart, matching: find.byIcon(Icons.add)),
    );
    await _waitFor(tester, find.descendant(of: cart, matching: find.text('2')));
    await _tap(
      tester,
      find.descendant(of: cart, matching: find.byIcon(Icons.remove)),
    );
    await _waitFor(tester, find.descendant(of: cart, matching: find.text('1')));

    await _tap(tester, find.text('Tiến hành thanh toán'));
    await _waitFor(tester, find.byType(CheckoutScreen));
    await _scrollTo(tester, find.text('VNPAY (QR/ATM/Visa)'));
    expect(find.text('Tiền mặt (COD)'), findsOneWidget);
    await _scrollTo(tester, find.text('Đặt hàng'));

    if (_write) {
      await _tap(tester, find.text('Đặt hàng'));
      await _waitFor(tester, find.text('Đặt hàng thành công'));
      return; // the order consumed the cart
    }

    await _back(tester);
    await _waitFor(tester, find.byType(CartScreen));
    await _tap(
      tester,
      find.descendant(of: cart, matching: find.byIcon(Icons.delete_outline)),
    );
    await _settle(tester, 1500);
    expect(
      find.descendant(of: cart, matching: find.text(_productQuery)),
      findsNothing,
    );
  }, timeout: _timeout);

  testWidgets('07 order history → order detail', (tester) async {
    await _launch(tester);
    await _tap(tester, find.byIcon(Icons.person_outline));
    // The demo account accumulates orders (web E2E runs create them too) and
    // profile tiles build lazily: drag the profile until an order tile is
    // actually built, then tap the newest one.
    await _waitFor(tester, find.byType(Scrollable));
    final end = DateTime.now().add(const Duration(seconds: 20));
    final orderTile = find.textContaining('#BK');
    while (orderTile.evaluate().isEmpty && DateTime.now().isBefore(end)) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await _settle(tester, 300);
    }
    if (orderTile.evaluate().isEmpty) {
      throw TestFailure('No #BK order tile appeared on the profile screen');
    }
    await tester.tap(orderTile.first);
    await _waitFor(tester, find.byType(OrderDetailScreen));
    await _waitFor(tester, find.text('Tổng cộng'));
  }, timeout: _timeout);

  testWidgets('08 membership: level, points and discount on profile', (
    tester,
  ) async {
    await _launch(tester);
    await _tap(tester, find.byIcon(Icons.person_outline));
    await _waitFor(tester, find.text('Hạng'));
    await _waitFor(tester, find.text('Điểm'));
    await _waitFor(tester, find.textContaining('Giảm giá thành viên'));
  }, timeout: _timeout);

  testWidgets('09 address book${_write ? ' + add address' : ''}', (
    tester,
  ) async {
    await _launch(tester);
    await _openProfileItem(tester, 'Sổ địa chỉ');
    await _waitFor(tester, find.byType(AddressesScreen));
    await _waitFor(tester, find.textContaining('Sổ địa chỉ ('));
    if (!_write) return;

    await _tap(tester, find.text('Thêm địa chỉ'));
    final street = 'E2E ${DateTime.now().millisecondsSinceEpoch}';
    for (final (label, value) in [
      ('Họ và tên', 'Linh Nguyen'),
      ('Số điện thoại', '0901234567'),
      ('Số nhà, tên đường', street),
      ('Phường / Xã', 'Bến Nghé'),
      ('Quận / Huyện', 'Quận 1'),
      ('Tỉnh / Thành phố', 'TP. Hồ Chí Minh'),
    ]) {
      await tester.enterText(find.widgetWithText(TextField, label), value);
    }
    await _tap(tester, find.text('Lưu địa chỉ'));
    await _waitFor(tester, find.textContaining(street));
  }, timeout: _timeout);

  testWidgets('10 notifications list', (tester) async {
    await _launch(tester);
    await _openProfileItem(tester, 'Thông báo');
    await _waitFor(tester, find.byType(NotificationsScreen));
    await _waitFor(tester, find.textContaining('Thông báo ('));
  }, timeout: _timeout);

  testWidgets('11 blog list → article', (tester) async {
    await _launch(tester);
    await _openProfileItem(tester, 'Blog');
    await _waitFor(tester, find.byType(BlogScreen));
    await _tap(tester, find.byType(BlogPostCard));
    await _waitFor(tester, find.byType(BlogDetailScreen));
  }, timeout: _timeout);

  testWidgets('12 policy pages list → page', (tester) async {
    await _launch(tester);
    await _openProfileItem(tester, 'Chính sách & Trang');
    await _waitFor(tester, find.byType(PagesScreen));
    await _tap(
      tester,
      find.descendant(
        of: find.descendant(
          of: find.byType(PagesScreen),
          matching: find.byType(ListView),
        ),
        matching: find.byType(InkWell),
      ),
    );
    await _waitFor(tester, find.byType(PageDetailScreen));
  }, timeout: _timeout);

  testWidgets('13 logout returns to login', (tester) async {
    await _launch(tester);
    await _tap(tester, find.byIcon(Icons.person_outline));
    await _tap(tester, find.byIcon(Icons.logout));
    await _waitFor(tester, find.widgetWithText(TextField, 'Email'));
  }, timeout: _timeout);
}
