import 'package:bakery_mobile/src/features/auth/presentation/screens/auth_screen.dart';
import 'package:bakery_mobile/src/core/theme/app_durations.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/catalog_keys.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/home_screen.dart';
import 'package:bakery_mobile/src/features/navigation/presentation/screens/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features/catalog/catalog_fixtures.dart';
import 'helpers/fake_api_client.dart';
import 'helpers/pump_app.dart';

/// Material's minimum touch target.
const double _minTap = 48;

void _expectTappable(WidgetTester tester, Finder finder) {
  final size = tester.getSize(finder);
  expect(size.width, greaterThanOrEqualTo(_minTap - 4), reason: '$finder');
  expect(size.height, greaterThanOrEqualTo(_minTap - 4), reason: '$finder');
}

/// The title of the banner currently shown in the home carousel.
String? _visibleBannerTitle(WidgetTester tester) {
  final banners = find.descendant(
    of: find.byKey(HomeKeys.banners),
    matching: find.byType(Text),
  );
  for (final element in banners.evaluate()) {
    final box = element.renderObject! as RenderBox;
    final center = box.localToGlobal(box.size.center(Offset.zero));
    final bannerBox = tester.getRect(find.byKey(HomeKeys.banners));
    if (bannerBox.contains(center)) return (element.widget as Text).data;
  }
  return null;
}

void main() {
  late FakeApiClient api;

  setUp(() => api = FakeApiClient());

  testWidgets('home header actions are named, 48dp buttons', (tester) async {
    final semantics = tester.ensureSemantics();
    stubHome(api);

    await pumpApp(tester, const HomeScreen(), api: api);
    await tester.pumpAndSettle();

    for (final label in ['Giỏ hàng', 'Yêu thích', 'Thông báo']) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      _expectTappable(tester, find.bySemanticsLabel(label));
    }
    // IconButton announces its tooltip (semantics `tooltip`, not `label`).
    expect(find.byTooltip('Mở menu'), findsOneWidget);
    _expectTappable(tester, find.byTooltip('Mở menu'));
    semantics.dispose();
  });

  testWidgets('product card actions are named for screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    stubHome(api);

    await pumpApp(tester, const HomeScreen(), api: api);
    await tester.pumpAndSettle();

    final addToCart = find.bySemanticsLabel(RegExp(r'^Thêm .+ vào giỏ$'));
    expect(addToCart, findsWidgets);
    _expectTappable(tester, addToCart.first);
    expect(
      find.bySemanticsLabel(RegExp(r'^(Thêm .+ vào|Bỏ .+ khỏi) yêu thích$')),
      findsWidgets,
    );
    semantics.dispose();
  });

  testWidgets('the banner carousel stays still when motion is reduced', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    stubHome(api);

    await pumpApp(tester, const HomeScreen(), api: api);
    await tester.pumpAndSettle();
    final first = _visibleBannerTitle(tester);

    await tester.pump(AppDurations.carouselAutoplay * 2);
    await tester.pumpAndSettle();

    expect(_visibleBannerTitle(tester), first);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the banner carousel advances by itself otherwise', (
    tester,
  ) async {
    stubHome(api);

    await pumpApp(tester, const HomeScreen(), api: api);
    await tester.pumpAndSettle();
    final first = _visibleBannerTitle(tester);

    await tester.pump(AppDurations.carouselAutoplay);
    await tester.pumpAndSettle();

    expect(_visibleBannerTitle(tester), isNot(first));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'bottom tabs stay icon-only on screen but are named for screen readers',
    (tester) async {
      final semantics = tester.ensureSemantics();
      stubHome(api);

      await pumpApp(tester, const MainLayout(), api: api);
      await tester.pumpAndSettle();

      final bar = find.byType(BottomAppBar);
      expect(bar, findsOneWidget);
      // Icon-only by design: no visible text or tooltips on the tabs.
      expect(
        find.descendant(of: bar, matching: find.byType(Text)),
        findsNothing,
      );
      expect(find.byTooltip('Trang chủ'), findsNothing);

      // ...but each tab has a spoken name, the current one is selected,
      // and every target is at least 48dp.
      const names = ['Trang chủ', 'Tìm kiếm', 'Yêu thích', 'Tài khoản'];
      for (final name in names) {
        final tab = find.descendant(
          of: bar,
          matching: find.bySemanticsLabel(name),
        );
        expect(tab, findsOneWidget, reason: name);
        final size = tester.getSize(tab);
        expect(size.width, greaterThanOrEqualTo(48), reason: name);
        expect(size.height, greaterThanOrEqualTo(48), reason: name);
      }
      expect(
        tester.getSemantics(find.bySemanticsLabel('Trang chủ')),
        matchesSemantics(
          label: 'Trang chủ',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      semantics.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('sign-in fields offer autofill to password managers', (
    tester,
  ) async {
    await pumpApp(tester, const AuthScreen(), api: api, signedIn: false);
    await tester.pumpAndSettle();

    final hints = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((field) => field.autofillHints)
        .toList();
    expect(hints, contains(contains(AutofillHints.email)));
    expect(hints, contains(contains(AutofillHints.password)));
    expect(find.byType(AutofillGroup), findsOneWidget);
  });
}
