import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_banner_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_blog_card_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_blog_detail_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_category_rail_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_notification_tile_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_order_card_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_product_grid_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_product_rail_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_tile_widget.dart';
import 'package:bakery_mobile/src/features/navigation/presentation/screens/app_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // AppGate's bootstrap reads the session token through TokenStorage, which
  // uses the secure-storage plugin; unmocked, that read never completes.
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpAppGate(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light(), home: const AppGate()),
      ),
    );
  }

  testWidgets('shows onboarding on first app launch', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await pumpAppGate(tester);

    expect(find.text('BAKERY SHOP'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();

    expect(find.text('Bánh mới mỗi ngày'), findsOneWidget);
    expect(find.text('Bỏ qua'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);
  });

  testWidgets('skip marks onboarding seen and opens auth flow', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await pumpAppGate(tester);
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();

    await tester.tap(find.text('Bỏ qua'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('bakery_onboarding_seen'), isTrue);
    expect(find.text('Email'), findsOneWidget);
    expect(
      find.text('Chào mừng bạn quay lại với những bánh tươi mỗi ngày.'),
      findsOneWidget,
    );
  });

  testWidgets('start button marks onboarding seen and opens auth flow', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await pumpAppGate(tester);
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();

    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục'));
    await tester.pumpAndSettle();

    expect(find.text('Đặt hàng nhanh hơn'), findsOneWidget);

    await tester.tap(find.text('Bắt đầu'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('bakery_onboarding_seen'), isTrue);
    expect(find.text('Email'), findsOneWidget);
  });

  testWidgets('skips onboarding after it has been completed', (tester) async {
    SharedPreferences.setMockInitialValues({'bakery_onboarding_seen': true});

    await pumpAppGate(tester);
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();

    expect(find.text('Bánh mới mỗi ngày'), findsNothing);
    expect(find.text('Email'), findsOneWidget);
  });

  testWidgets('renders shared skeleton loading widgets', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                SkeletonTileWidget(),
                SkeletonBannerWidget(),
                SkeletonCategoryRailWidget(),
                SkeletonProductGridWidget(itemCount: 2),
                SkeletonProductRailWidget(itemCount: 2),
                SkeletonBlogCardWidget(),
                SkeletonBlogDetailWidget(),
                SkeletonNotificationTileWidget(),
                SkeletonOrderCardWidget(),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SkeletonTileWidget), findsWidgets);
    expect(find.byType(SkeletonBannerWidget), findsOneWidget);
    expect(find.byType(SkeletonProductGridWidget), findsOneWidget);
    expect(find.byType(SkeletonProductRailWidget), findsOneWidget);
    expect(find.byType(SkeletonBlogCardWidget), findsOneWidget);
    expect(find.byType(SkeletonBlogDetailWidget), findsOneWidget);
    expect(find.byType(SkeletonNotificationTileWidget), findsOneWidget);
    expect(find.byType(SkeletonOrderCardWidget), findsOneWidget);
  });
}
