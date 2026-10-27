import 'package:bakery_mobile/src/features/profile/presentation/delete_account_keys.dart';
import 'package:bakery_mobile/src/features/profile/presentation/screens/delete_account_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_api_client.dart';
import '../../helpers/fixture.dart';
import '../../helpers/pump_app.dart';

const _path = '/api/auth/delete-account';
const _otpPath = '/api/auth/delete-account/otp';

Finder _otpField() => find.descendant(
  of: find.byKey(DeleteAccountKeys.otp),
  matching: find.byType(TextField),
);

FilledButton _submitButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(DeleteAccountKeys.submit));

// The form sits below the data summary, past the test viewport, and the
// ListView only builds what is near it — scroll until the widget exists.
Future<void> _scrollTo(WidgetTester tester, Key key) async {
  await tester.scrollUntilVisible(
    find.byKey(key),
    100,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Key key) async {
  await _scrollTo(tester, key);
  await tester.tap(find.byKey(key));
}

Future<void> _sendOtp(WidgetTester tester) async {
  await _tapVisible(tester, DeleteAccountKeys.sendOtp);
  await tester.pumpAndSettle();
}

Future<void> _fillAndSubmit(WidgetTester tester) async {
  await _sendOtp(tester);
  await tester.enterText(_otpField(), '482913');
  await _tapVisible(tester, DeleteAccountKeys.confirm);
  await tester.pump();
  await _tapVisible(tester, DeleteAccountKeys.submit);
  await tester.pumpAndSettle();
}

void main() {
  late FakeApiClient api;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    api = FakeApiClient();
    api.stubFixture('POST', _otpPath, 'auth/delete_account_otp_success.json');
  });

  testWidgets('code field appears only after the code is sent', (tester) async {
    await pumpApp(tester, const DeleteAccountScreen(), api: api);

    expect(find.byKey(DeleteAccountKeys.otp), findsNothing);
    await _sendOtp(tester);

    expect(api.callsTo('POST', _otpPath), hasLength(1));
    expect(find.byKey(DeleteAccountKeys.otp), findsOneWidget);
    expect(find.text('Gửi lại mã'), findsOneWidget);
  });

  testWidgets('submit stays disabled until a 6-digit code + confirmation', (
    tester,
  ) async {
    await pumpApp(tester, const DeleteAccountScreen(), api: api);
    await _sendOtp(tester);
    await _scrollTo(tester, DeleteAccountKeys.submit);

    expect(_submitButton(tester).onPressed, isNull);
    await tester.enterText(_otpField(), '4829');
    await _tapVisible(tester, DeleteAccountKeys.confirm);
    await tester.pump();
    expect(_submitButton(tester).onPressed, isNull);
    await tester.enterText(_otpField(), '482913');
    await tester.pump();
    expect(_submitButton(tester).onPressed, isNotNull);
    expect(api.callsTo('POST', _path), isEmpty);
  });

  testWidgets('success posts the code and confirms', (tester) async {
    api.stubFixture('POST', _path, 'auth/delete_account_success.json');

    await pumpApp(tester, const DeleteAccountScreen(), api: api);
    await _fillAndSubmit(tester);

    expect(api.callsTo('POST', _path).single.body, {'otp': '482913'});
    expect(find.text('Tài khoản của bạn đã được xóa.'), findsOneWidget);
    expect(find.byKey(DeleteAccountKeys.error), findsNothing);
  });

  testWidgets('open orders: shows the server reason and stays put', (
    tester,
  ) async {
    const fixtureName = 'auth/delete_account_open_orders.json';
    api.stubError('POST', _path, fixtureName: fixtureName, statusCode: 409);

    await pumpApp(tester, const DeleteAccountScreen(), api: api);
    await _fillAndSubmit(tester);

    expect(find.byKey(DeleteAccountKeys.error), findsOneWidget);
    expect(find.text(fixtureError(fixtureName).message), findsOneWidget);
    expect(find.byType(DeleteAccountScreen), findsOneWidget);
  });
}
