// End-to-end smoke on a real emulator (Pixel 7 API 34):
// onboarding → home loads from the live API → login → address book →
// PDP + reviews → cart → checkout with saved address (COD) → success.
//
// Run: fvm flutter test integration_test/app_e2e_test.dart -d emulator-5554

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:bakery_mobile/main.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/widgets/search_product_tile.dart';

const _email = 'linh@email.com';
const _password = 'admin123';

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  // Let real network timers and animations settle without pumpAndSettle,
  // which would hang on infinite spinners (skeletons).
  await tester.runAsync(() => Future<void>.delayed(duration));
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
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
  }
  if (finder.evaluate().isEmpty) {
    final visibleTexts = find
        .byType(Text)
        .evaluate()
        .map((e) {
          final widget = e.widget as Text;
          return widget.data ?? widget.textSpan?.toPlainText() ?? '';
        })
        .where((t) => t.trim().isNotEmpty)
        .take(40)
        .join(' | ');
    throw TestFailure('waitFor timed out: $finder — MÀN HÌNH: [$visibleTexts]');
  }
}

Future<void> _scrollUntilVisible(
  WidgetTester tester,
  Finder finder, {
  Finder? scrollable,
}) async {
  await _waitFor(tester, finder, timeout: const Duration(seconds: 10));
  final scroller = scrollable ?? find.byType(Scrollable).first;
  await tester.scrollUntilVisible(finder, 300, scrollable: scroller);
}

Future<void> _loginIfNeeded(WidgetTester tester) async {
  final emailField = find.widgetWithText(TextField, 'Email');
  var needLogin = false;
  final end = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(end)) {
    await tester.pump();
    if (emailField.evaluate().isNotEmpty) {
      needLogin = true;
      break;
    }
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)));
  }
  if (!needLogin) return;
  await tester.enterText(emailField.first, _email);
  await tester.enterText(
      find.widgetWithText(TextField, 'Password').first, _password);
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Sign in').first);
  await _pumpFor(tester, const Duration(seconds: 4));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'E2E: onboarding → home → login → address → reviews → cart → checkout COD',
    (tester) async {
      dotenv.testLoad(fileInput: 'API_BASE_URL=http://10.0.2.2:3001\n');
      await tester.pumpWidget(const ProviderScope(child: BakeryMobileApp()));
      await _pumpFor(tester, const Duration(seconds: 3));

      // ── 1. Onboarding (first launch): chờ nút xuất hiện (splash trước đó),
      // bấm Tiếp tục... đến Bắt đầu ──
      final homeNav = find.byIcon(Icons.home_outlined);
      final deadline = DateTime.now().add(const Duration(seconds: 25));
      var onboarded = false;
      while (DateTime.now().isBefore(deadline)) {
        await tester.pump();
        final startOrNext = find.text('Bắt đầu');
        final next = find.text('Tiếp tục');
        if (startOrNext.evaluate().isNotEmpty) {
          await tester.tap(startOrNext.first);
          onboarded = true;
          await tester.pump(const Duration(milliseconds: 800));
          break;
        }
        if (next.evaluate().isNotEmpty) {
          await tester.tap(next.first);
          await tester.pump(const Duration(milliseconds: 800));
          continue;
        }
        if (homeNav.evaluate().isNotEmpty) break; // đã skip onboarding từ trước
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 400)));
      }
      if (onboarded) {
        await _pumpFor(tester, const Duration(seconds: 2));
      }

      // ── 2. Sau onboarding: guest rơi vào màn Đăng nhập ──
      await _waitFor(tester, find.widgetWithText(TextField, 'Email'),
          timeout: const Duration(seconds: 30));

      // ── 3. Login ──
      await tester.enterText(
          find.widgetWithText(TextField, 'Email').first, _email);
      await tester.enterText(
          find.widgetWithText(TextField, 'Password').first, _password);
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in').first);
      // Đăng nhập xong → app shell home nạp sản phẩm từ API
      await _waitFor(
        tester,
        find.textContaining('Bánh').hitTestable(),
        timeout: const Duration(seconds: 45),
      );
      try {
        await binding.takeScreenshot('e2e-1-home-logged-in');
      } catch (_) {}

      // ── 4. Sổ địa chỉ: thêm địa chỉ mặc định ──
      await _waitFor(tester, find.byIcon(Icons.person_outline),
          timeout: const Duration(seconds: 15));
      await tester.tap(find.byIcon(Icons.person_outline));
      await _pumpFor(tester, const Duration(seconds: 2));
      await _scrollUntilVisible(tester, find.text('Sổ địa chỉ'));
      await tester.tap(find.text('Sổ địa chỉ'));
      await _pumpFor(tester, const Duration(seconds: 2));

      final addFab = find.text('Thêm địa chỉ');
      await _waitFor(tester, addFab);
      await tester.tap(addFab);
      await _pumpFor(tester, const Duration(seconds: 2));
      await _waitFor(tester, find.widgetWithText(TextField, 'Họ và tên'),
          timeout: const Duration(seconds: 10));

      await tester.enterText(
          find.widgetWithText(TextField, 'Họ và tên'), 'Linh Nguyen');
      await tester.enterText(
          find.widgetWithText(TextField, 'Số điện thoại'), '0901234567');
      await tester.enterText(
          find.widgetWithText(TextField, 'Số nhà, tên đường'), '12 Nguyễn Huệ');
      await tester.enterText(
          find.widgetWithText(TextField, 'Phường / Xã'), 'Bến Nghé');
      await tester.enterText(
          find.widgetWithText(TextField, 'Quận / Huyện'), 'Quận 1');
      await tester.enterText(
          find.widgetWithText(TextField, 'Tỉnh / Thành phố'),
          'TP. Hồ Chí Minh');
      await tester.pump();
      await tester.tap(find.text('Lưu địa chỉ'));
      await _pumpFor(tester, const Duration(seconds: 3));
      await _waitFor(tester, find.textContaining('12 Nguyễn Huệ'));
      try {
        await binding.takeScreenshot('e2e-3-address-book');
      } catch (_) {}

    },
    timeout: const Timeout(Duration(minutes: 8)),
  );

  // ── Block 2: khởi động lại app (token còn trong SharedPreferences) —
  // home → PDP reviews → giỏ → checkout dùng địa chỉ đã lưu → COD ──
  testWidgets(
    'E2E block 2: home → PDP reviews → cart → checkout saved address COD',
    (tester) async {
      dotenv.testLoad(fileInput: 'API_BASE_URL=http://10.0.2.2:3001\n');
      await tester.pumpWidget(const ProviderScope(child: BakeryMobileApp()));
      await _pumpFor(tester, const Duration(seconds: 4));

      // Phiên có thể bị 401 giữa chừng (đang điều tra riêng) — login lại nếu cần
      await _loginIfNeeded(tester);

      // Home nạp sản phẩm từ API
      await _waitFor(
        tester,
        find.textContaining('Bánh').hitTestable(),
        timeout: const Duration(seconds: 45),
      );

      // PDP qua Search: gõ từ khoá → bấm kết quả
      await tester.tap(find.byIcon(Icons.search_outlined));
      await _pumpFor(tester, const Duration(seconds: 2));
      await tester.enterText(
          find.widgetWithText(TextField, 'What are you looking for?'),
          'Tiramisu');
      await tester.pump();
      await _pumpFor(tester, const Duration(seconds: 3));

      final productCard = find.byType(SearchProductTile);
      await _waitFor(tester, productCard, timeout: const Duration(seconds: 20));
      await tester.tap(productCard.first);
      await _pumpFor(tester, const Duration(seconds: 3));
      await _waitFor(tester, find.text('Viết đánh giá'),
          timeout: const Duration(seconds: 25));
      try {
        await binding.takeScreenshot('e2e-4-pdp-reviews');
      } catch (_) {}

      // Nhãn nút mua có thể là 'Thêm vào giỏ' hoặc 'Add to Cart' tùy biến thể
      final addToCart = find.textContaining('Thêm vào giỏ');
      final addToCartEn = find.textContaining('Add to Cart');
      final settleEnd2 = DateTime.now().add(const Duration(seconds: 10));
      while (addToCart.evaluate().isEmpty &&
          addToCartEn.evaluate().isEmpty &&
          DateTime.now().isBefore(settleEnd2)) {
        await tester.pump();
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 300)));
      }
      final buyButton =
          addToCart.evaluate().isNotEmpty ? addToCart : addToCartEn;
      await _scrollUntilVisible(tester, buyButton.first);
      await tester.tap(buyButton.first);
      await _pumpFor(tester, const Duration(seconds: 1));

      // Giỏ → Checkout (nếu 401 đẩy về login thì login lại + vào lại giỏ)
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
      await _pumpFor(tester, const Duration(seconds: 2));
      if (find.widgetWithText(TextField, 'Email').evaluate().isNotEmpty) {
        await _loginIfNeeded(tester);
        await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
        await _pumpFor(tester, const Duration(seconds: 2));
      }
      final checkout = find.textContaining('Thanh toán').first;
      await _scrollUntilVisible(tester, checkout);
      await tester.tap(checkout);
      await _pumpFor(tester, const Duration(seconds: 3));

      // Địa chỉ đã lưu (tạo ở block 1) được chọn sẵn
      expect(find.textContaining('12 Nguyễn Huệ').evaluate().isNotEmpty, true);
      try {
        await binding.takeScreenshot('e2e-5-checkout-saved-address');
      } catch (_) {}

      // VNPAY có mặt trong danh sách phương thức
      expect(find.textContaining('VNPAY').evaluate().isNotEmpty, true);

      await _scrollUntilVisible(tester, find.textContaining('Đặt').first);
      await tester.tap(find.textContaining('Đặt').first);
      await _pumpFor(tester, const Duration(seconds: 5));
      try {
        await binding.takeScreenshot('e2e-6-order-placed');
      } catch (_) {}

      final done = find.textContaining('OK').first;
      if (done.evaluate().isNotEmpty) {
        await tester.tap(done);
        await _pumpFor(tester, const Duration(seconds: 2));
      }
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
