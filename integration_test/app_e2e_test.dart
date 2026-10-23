// End-to-end tests per customer feature, on a real emulator against a running
// bakery-web (the API URL comes from the dart-define config, e.g. port 3000
// in config/dev.json):
//
//   fvm flutter test integration_test/app_e2e_test.dart -d emulator-5554 \
//     --flavor dev --dart-define-from-file=config/dev.json
//
// Default run is read-only towards the server: anything it changes is undone
// in the same test (wishlist toggled back, cart item removed). Steps that
// create real data or cost money — saving an address, placing an order,
// sending a chatbot message (OpenAI) — only run with:
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
import 'package:bakery_mobile/src/features/chatbot/presentation/screens/chatbot_screen.dart';
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
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 60,
    );
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
        find.widgetWithText(TextField, 'Password').first,
        _password,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in').first);
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

bool _isFavorite(WidgetTester tester) =>
    tester.widget<FavoriteIconWidget>(_pdpFavorite().first).isFavorite;

Future<void> _toggleFavoriteAndWait(WidgetTester tester) async {
  final before = _isFavorite(tester);
  await _tap(
    tester,
    find.ancestor(of: _pdpFavorite().first, matching: find.byType(IconButton)),
  );
  final end = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(end)) {
    await _settle(tester, 300);
    final w = tester.widget<FavoriteIconWidget>(_pdpFavorite().first);
    if (!w.isPending && w.isFavorite != before) return;
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
    expect(find.text('Add to Cart'), findsOneWidget);
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
    final initial = _isFavorite(tester);
    await _toggleFavoriteAndWait(tester);
    // Whichever state it is in now, make sure it is a favorite for the check.
    if (!_isFavorite(tester)) await _toggleFavoriteAndWait(tester);

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
    if (_isFavorite(tester) != initial) await _toggleFavoriteAndWait(tester);
    expect(_isFavorite(tester), initial);
  }, timeout: _timeout);

  testWidgets('06 cart: add, change quantity, checkout screen, remove', (
    tester,
  ) async {
    await _launch(tester);
    await _openProduct(tester);
    await _tap(tester, find.text('Add to Cart'));
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

    await _tap(tester, find.text('Proceed to checkout'));
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
    await _scrollTo(tester, find.text('Order History'));
    await _scrollTo(tester, find.textContaining('#BK'));
    await _tap(tester, find.textContaining('#BK'));
    await _waitFor(tester, find.byType(OrderDetailScreen));
    await _waitFor(tester, find.text('Tổng cộng'));
  }, timeout: _timeout);

  testWidgets('08 membership: level, points and discount on profile', (
    tester,
  ) async {
    await _launch(tester);
    await _tap(tester, find.byIcon(Icons.person_outline));
    await _waitFor(tester, find.text('Level'));
    await _waitFor(tester, find.text('Points'));
    await _waitFor(tester, find.textContaining('membership discount'));
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
    await _openProfileItem(tester, 'Notifications');
    await _waitFor(tester, find.byType(NotificationsScreen));
    await _waitFor(tester, find.textContaining('Notifications ('));
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
    await _openProfileItem(tester, 'Policy & Pages');
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

  testWidgets('13 chatbot${_write ? ' sends a message' : ' screen'}', (
    tester,
  ) async {
    await _launch(tester);
    await _tap(tester, find.byIcon(Icons.chat_bubble_outline));
    await _waitFor(tester, find.byType(ChatbotScreen));
    final input = find.widgetWithText(TextField, 'Nhap tin nhan...');
    await _waitFor(tester, input);
    if (!_write) return;

    final before = find
        .descendant(of: find.byType(ChatbotScreen), matching: find.byType(Text))
        .evaluate()
        .length;
    await tester.enterText(input, 'Gợi ý bánh sinh nhật');
    await _tap(tester, find.byIcon(Icons.send));
    final end = DateTime.now().add(const Duration(seconds: 60));
    while (DateTime.now().isBefore(end)) {
      await _settle(tester, 500);
      final now = find
          .descendant(
            of: find.byType(ChatbotScreen),
            matching: find.byType(Text),
          )
          .evaluate()
          .length;
      if (now >= before + 2) return; // user message + bot reply
    }
    throw TestFailure('Chatbot did not reply within 60s');
  }, timeout: _timeout);

  testWidgets('14 logout returns to login', (tester) async {
    await _launch(tester);
    await _tap(tester, find.byIcon(Icons.person_outline));
    await _tap(tester, find.byIcon(Icons.logout));
    await _waitFor(tester, find.widgetWithText(TextField, 'Email'));
  }, timeout: _timeout);
}
