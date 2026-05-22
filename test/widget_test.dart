import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/core/widgets/skeleton_widgets.dart';
import 'package:bakery_mobile/src/features/navigation/presentation/screens/app_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
      find.text('Welcome back to your daily bread and pastry picks.'),
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
                SkeletonTile(),
                SkeletonBanner(),
                SkeletonCategoryRail(),
                SkeletonProductGrid(itemCount: 2),
                SkeletonProductRail(itemCount: 2),
                SkeletonBlogCard(),
                SkeletonBlogDetail(),
                SkeletonNotificationTile(),
                SkeletonOrderCard(),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SkeletonTile), findsWidgets);
    expect(find.byType(SkeletonBanner), findsOneWidget);
    expect(find.byType(SkeletonProductGrid), findsOneWidget);
    expect(find.byType(SkeletonProductRail), findsOneWidget);
    expect(find.byType(SkeletonBlogCard), findsOneWidget);
    expect(find.byType(SkeletonBlogDetail), findsOneWidget);
    expect(find.byType(SkeletonNotificationTile), findsOneWidget);
    expect(find.byType(SkeletonOrderCard), findsOneWidget);
  });
}
