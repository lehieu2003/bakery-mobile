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

Finder _passwordField() => find.descendant(
  of: find.byKey(DeleteAccountKeys.password),
  matching: find.byType(TextField),
);

FilledButton _submitButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(DeleteAccountKeys.submit));

Future<void> _fillAndSubmit(WidgetTester tester) async {
  await tester.enterText(_passwordField(), 'secret-1');
  await tester.tap(find.byKey(DeleteAccountKeys.confirm));
  await tester.pump();
  await tester.ensureVisible(find.byKey(DeleteAccountKeys.submit));
  await tester.tap(find.byKey(DeleteAccountKeys.submit));
  await tester.pumpAndSettle();
}

void main() {
  late FakeApiClient api;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    api = FakeApiClient();
  });

  testWidgets('submit stays disabled until password + confirmation', (
    tester,
  ) async {
    await pumpApp(tester, const DeleteAccountScreen(), api: api);

    expect(_submitButton(tester).onPressed, isNull);
    await tester.enterText(_passwordField(), 'secret-1');
    await tester.pump();
    expect(_submitButton(tester).onPressed, isNull);
    await tester.tap(find.byKey(DeleteAccountKeys.confirm));
    await tester.pump();
    expect(_submitButton(tester).onPressed, isNotNull);
    expect(api.calls, isEmpty);
  });

  testWidgets('success posts the password and confirms', (tester) async {
    api.stubFixture('POST', _path, 'auth/delete_account_success.json');

    await pumpApp(tester, const DeleteAccountScreen(), api: api);
    await _fillAndSubmit(tester);

    expect(api.callsTo('POST', _path).single.body, {'password': 'secret-1'});
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
