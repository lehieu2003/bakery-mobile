import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/navigation/app_navigator.dart';
import 'package:bakery_mobile/src/core/push/push_messaging.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:bakery_mobile/src/features/notifications/presentation/widgets/push_notifications_host.dart';
import 'package:bakery_mobile/src/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_api_client.dart';
import '../../helpers/fake_push_messaging.dart';
import '../../helpers/pump_app.dart';

const _tokenPath = '/api/notifications/device-token';

const _orderUpdate = PushMessage(
  title: 'Đơn hàng đã sẵn sàng',
  body: 'Đơn #BK1 đã sẵn sàng để nhận hoặc giao.',
  data: {'eventType': 'ORDER_STATUS_CHANGED', 'orderNumber': 'BK1'},
);

const _announcement = PushMessage(
  title: 'Bánh mới',
  body: 'Thử ngay hôm nay',
  data: {'eventType': 'CAMPAIGN_TRIGGERED', 'entityId': 'n-1'},
);

void main() {
  late FakeApiClient api;
  late FakePushMessaging push;

  setUp(() {
    api = FakeApiClient()
      ..stub('POST', _tokenPath, (_) => {'id': 'dt-1'})
      ..stub('GET', '/api/notifications', (_) => {'notifications': []});
    push = FakePushMessaging();
  });

  Future<void> pumpHost(WidgetTester tester, {bool signedIn = true}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(
          api,
          signedIn: signedIn,
          extra: [pushMessagingProvider.overrideWithValue(push)],
        ),
        child: MaterialApp(
          theme: AppTheme.light(),
          navigatorKey: appNavigatorKey,
          builder: (context, child) => PushNotificationsHost(child: child!),
          home: const Scaffold(body: Text('Trang chủ')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  /// Pushed routes load data the test does not stub; only the route matters.
  Future<void> settleRoute(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('a restored session registers this phone for push', (
    tester,
  ) async {
    await pumpHost(tester);

    expect(push.topics, ['announcements']);
    expect(api.callsTo('POST', _tokenPath), hasLength(1));
  });

  testWidgets('signed out, nothing is registered', (tester) async {
    await pumpHost(tester, signedIn: false);

    expect(push.permissionRequests, 0);
    expect(api.callsTo('POST', _tokenPath), isEmpty);
  });

  testWidgets('a push while the app is open shows a snack bar and refreshes', (
    tester,
  ) async {
    await pumpHost(tester);

    push.receive(_orderUpdate);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text(
        'Đơn hàng đã sẵn sàng: Đơn #BK1 đã sẵn sàng để nhận hoặc giao.',
      ),
      findsOneWidget,
    );
    expect(api.callsTo('GET', '/api/notifications'), isNotEmpty);

    await tester.tap(find.text('Xem'));
    await settleRoute(tester);

    final detail = tester.widget<OrderDetailScreen>(
      find.byType(OrderDetailScreen),
    );
    expect(detail.orderNumber, 'BK1');
  });

  testWidgets('tapping an announcement opens the notification list', (
    tester,
  ) async {
    await pumpHost(tester);

    push.tap(_announcement);
    await settleRoute(tester);

    expect(find.byType(NotificationsScreen), findsOneWidget);
  });

  testWidgets('the push that launched the app is opened after sign-in', (
    tester,
  ) async {
    push.launchMessage = _orderUpdate;
    await pumpHost(tester);
    await settleRoute(tester);

    expect(find.byType(OrderDetailScreen), findsOneWidget);
  });
}
