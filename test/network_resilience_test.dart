import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/core/network/connectivity.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/shared/utils/error_message.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/offline_banner_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(ProviderContainer container, Widget child) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: child),
      ),
    );

void main() {
  group('userErrorMessage', () {
    test('shows ApiException messages, which are user-facing', () {
      expect(
        userErrorMessage(ApiException('Hết hàng', statusCode: 400)),
        'Hết hàng',
      );
    });

    test('never shows the text of other errors', () {
      expect(
        userErrorMessage(const FormatException('Unexpected character at 1')),
        unexpectedErrorMessage,
      );
    });
  });

  test('ApiException kinds follow the status code', () {
    expect(ApiException('x').kind, ApiErrorKind.network);
    expect(ApiException('x', statusCode: 401).kind, ApiErrorKind.unauthorized);
    expect(ApiException('x', statusCode: 404).kind, ApiErrorKind.client);
    expect(ApiException('x', statusCode: 503).kind, ApiErrorKind.server);
    expect(
      ApiException('x', kind: ApiErrorKind.timeout).isConnectivityIssue,
      isTrue,
    );
  });

  testWidgets('ErrorRetryWidget shows offline state and retries on reconnect', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    var retries = 0;
    await tester.pumpWidget(
      _host(
        container,
        ErrorRetryWidget(message: 'Không tải được', onRetry: () => retries++),
      ),
    );
    expect(find.text('Mất kết nối'), findsNothing);

    container.read(isOnlineProvider.notifier).state = false;
    await tester.pump();
    expect(find.text('Mất kết nối'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    expect(retries, 0);

    container.read(isOnlineProvider.notifier).state = true;
    await tester.pump();
    expect(retries, 1);
    expect(find.text('Mất kết nối'), findsNothing);
  });

  testWidgets('the offline banner appears only while offline', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      _host(container, const OfflineBannerWidget(child: Text('Trang chủ'))),
    );
    expect(find.textContaining('Mất kết nối mạng'), findsNothing);

    container.read(isOnlineProvider.notifier).state = false;
    await tester.pumpAndSettle();
    expect(find.textContaining('Mất kết nối mạng'), findsOneWidget);
    expect(find.text('Trang chủ'), findsOneWidget);

    container.read(isOnlineProvider.notifier).state = true;
    await tester.pumpAndSettle();
    expect(find.textContaining('Mất kết nối mạng'), findsNothing);
  });
}
