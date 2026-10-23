import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/shared/widgets/app_network_image_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/empty_state_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/discount_badge_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/favorite_icon_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/info_row_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/initial_avatar_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/order_status_pill_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/price_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/section_card_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/summary_row_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => ProviderScope(
  child: MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  ),
);

void main() {
  group('AppNetworkImageWidget', () {
    testWidgets('empty url shows the empty icon in a sized box, no network', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Center(
            child: AppNetworkImageWidget(
              url: '',
              width: 84,
              height: 84,
              emptyIcon: Icons.cake_outlined,
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.cake_outlined), findsOneWidget);
      expect(
        tester.getSize(find.byType(AppNetworkImageWidget)),
        const Size(84, 84),
      );
    });

    testWidgets('a failed load falls back to the error icon', (tester) async {
      // flutter_test answers every HTTP request with 400 → errorBuilder.
      await tester.pumpWidget(
        _host(
          const AppNetworkImageWidget(
            url: 'https://cdn.example.com/cake.jpg',
            width: 52,
            height: 52,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    });

    testWidgets('null icons give a plain box; placeholder replaces it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              AppNetworkImageWidget(
                url: null,
                width: 20,
                height: 20,
                emptyIcon: null,
              ),
              AppNetworkImageWidget(
                url: '',
                width: 20,
                height: 20,
                placeholder: ColoredBox(color: Color(0xFFD8D8D8)),
              ),
            ],
          ),
        ),
      );

      expect(find.byType(Icon), findsNothing);
      expect(find.byType(ColoredBox), findsWidgets);
    });

    testWidgets('borderRadius clips the image', (tester) async {
      await tester.pumpWidget(
        _host(
          AppNetworkImageWidget(
            url: '',
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

      expect(find.byType(ClipRRect), findsOneWidget);
    });
  });

  testWidgets('LoadingWidget centers a spinner, sized when asked', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const LoadingWidget(size: 24)));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.getSize(find.byType(CircularProgressIndicator)),
      const Size(24, 24),
    );
  });

  group('ErrorRetryWidget', () {
    testWidgets('full: title, message and a working retry button', (
      tester,
    ) async {
      var retries = 0;
      await tester.pumpWidget(
        _host(
          ErrorRetryWidget(
            title: 'Không tải được đơn hàng',
            message: 'Mất kết nối',
            onRetry: () => retries++,
            secondaryAction: const Text('Quay lại'),
          ),
        ),
      );

      expect(find.text('Không tải được đơn hàng'), findsOneWidget);
      expect(find.text('Mất kết nối'), findsOneWidget);
      expect(find.text('Quay lại'), findsOneWidget);
      await tester.tap(find.text('Thử lại'));
      expect(retries, 1);
    });

    testWidgets('compact uses a text button; no onRetry hides it', (
      tester,
    ) async {
      var retries = 0;
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              ErrorRetryWidget(
                message: 'Lỗi',
                compact: true,
                onRetry: () => retries++,
              ),
              const ErrorRetryWidget(message: 'Không thể thử lại'),
            ],
          ),
        ),
      );

      expect(find.widgetWithText(TextButton, 'Thử lại'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      await tester.tap(find.text('Thử lại'));
      expect(retries, 1);
    });
  });

  testWidgets('EmptyStateWidget shows its message and optional icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const EmptyStateWidget(
          message: 'Chưa có đơn hàng',
          icon: Icons.receipt_long_outlined,
        ),
      ),
    );

    expect(find.text('Chưa có đơn hàng'), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
  });

  group('DiscountBadgeWidget', () {
    testWidgets('renders -NN% and sizes per variant', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DiscountBadgeWidget(percent: 15, key: Key('s')),
              DiscountBadgeWidget(
                percent: 15,
                variant: DiscountBadgeVariant.large,
                key: Key('l'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('-15%'), findsNWidgets(2));
      final small = tester.getSize(find.byKey(const Key('s')));
      final large = tester.getSize(find.byKey(const Key('l')));
      expect(large.height, greaterThan(small.height));
    });
  });

  group('PriceWidget', () {
    testWidgets('formats VND and strikes the higher compare price', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const PriceWidget(price: 120000, comparePrice: 150000)),
      );

      expect(find.text('120.000 ₫'), findsOneWidget);
      final compare = tester.widget<Text>(find.text('150.000 ₫'));
      expect(compare.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('hides a compare price that is not higher', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              PriceWidget(price: 120000, comparePrice: 120000),
              PriceWidget(price: 90000, variant: PriceVariant.card),
            ],
          ),
        ),
      );

      expect(find.text('120.000 ₫'), findsOneWidget);
      expect(find.text('90.000 ₫'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && w.style?.decoration == TextDecoration.lineThrough,
        ),
        findsNothing,
      );
    });

    testWidgets('chip variant wraps the price in a pill', (tester) async {
      await tester.pumpWidget(
        _host(const PriceWidget(price: 50000, variant: PriceVariant.chip)),
      );

      expect(
        find.ancestor(
          of: find.text('50.000 ₫'),
          matching: find.byType(Container),
        ),
        findsWidgets,
      );
    });
  });

  testWidgets('OrderStatusPillWidget labels statuses case-insensitively', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            OrderStatusPillWidget(status: 'PENDING'),
            OrderStatusPillWidget(status: 'completed'),
            OrderStatusPillWidget(status: 'MYSTERY'),
          ],
        ),
      ),
    );

    expect(find.text('Chờ xác nhận'), findsOneWidget);
    expect(find.text('Hoàn thành'), findsOneWidget);
    expect(find.text('MYSTERY'), findsOneWidget);
  });

  testWidgets('SectionCardWidget + InfoRowWidget + SummaryRowWidget', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SectionCardWidget(
          title: 'Thanh toán',
          child: Column(
            children: [
              InfoRowWidget(label: 'Phương thức', value: 'VNPAY'),
              SummaryRowWidget(label: 'Tạm tính', value: '90.000 ₫'),
              SummaryRowWidget(
                label: 'Tổng cộng',
                value: '117.300 ₫',
                variant: SummaryRowVariant.total,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Thanh toán'), findsOneWidget);
    expect(find.text('VNPAY'), findsOneWidget);
    final total = tester.widget<Text>(find.text('117.300 ₫'));
    final regular = tester.widget<Text>(find.text('90.000 ₫'));
    expect(total.style?.fontWeight, FontWeight.w800);
    expect(regular.style?.fontWeight, isNot(FontWeight.w800));
  });

  group('InitialAvatarWidget', () {
    test('initialOf uppercases the first letter, falls back when blank', () {
      expect(InitialAvatarWidget.initialOf('hieu'), 'H');
      expect(InitialAvatarWidget.initialOf('  Ánh '), 'Á');
      expect(InitialAvatarWidget.initialOf('   '), '?');
      expect(InitialAvatarWidget.initialOf(null, fallback: 'A'), 'A');
    });

    testWidgets('renders the initial', (tester) async {
      await tester.pumpWidget(_host(const InitialAvatarWidget(name: 'linh')));
      expect(find.text('L'), findsOneWidget);
    });
  });

  group('FavoriteIconWidget', () {
    testWidgets('filled red when favorite, outlined otherwise', (tester) async {
      await tester.pumpWidget(
        _host(
          const Row(
            children: [
              FavoriteIconWidget(isFavorite: true),
              FavoriteIconWidget(isFavorite: false),
            ],
          ),
        ),
      );

      final filled = tester.widget<Icon>(find.byIcon(Icons.favorite));
      expect(filled.color, FavoriteIconWidget.activeColor);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('pending shows a spinner in the same footprint', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const Center(
            child: FavoriteIconWidget(isFavorite: false, isPending: true),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
      expect(
        tester.getSize(find.byType(FavoriteIconWidget)),
        const Size(24, 24),
      );
    });
  });

  testWidgets('SummaryRowWidget right-aligns a short value', (tester) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 400,
          child: SummaryRowWidget(label: 'Tạm tính', value: '90.000 ₫'),
        ),
      ),
    );

    final row = tester.getRect(find.byType(SummaryRowWidget));
    final value = tester.getRect(find.text('90.000 ₫'));
    expect(value.right, moreOrLessEquals(row.right, epsilon: 0.5));
  });

  testWidgets('SummaryRowWidget wraps a long value instead of overflowing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 240,
          child: SummaryRowWidget(
            label: 'Mã sản phẩm',
            value: 'cmm8zdhm5000cuy3o5q4128t2-very-long-identifier',
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final row = tester.getRect(find.byType(SummaryRowWidget));
    final value = tester.getRect(find.textContaining('cmm8zdhm'));
    expect(value.right, lessThanOrEqualTo(row.right + 0.5));
  });
}
