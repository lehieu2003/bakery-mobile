import 'package:bakery_mobile/src/features/chatbot/presentation/chatbot_keys.dart';
import 'package:bakery_mobile/src/features/chatbot/presentation/screens/chatbot_screen.dart';
import 'package:bakery_mobile/src/features/chatbot/presentation/widgets/suggested_product_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_api_client.dart';
import '../../helpers/fixture.dart';
import '../../helpers/pump_app.dart';

const _path = '/api/chat';
const _success = 'chatbot/chat_success.json';
const _empty = 'chatbot/chat_empty.json';

Map<String, dynamic> _reply() => fixtureData(_success) as Map<String, dynamic>;

Finder _inputField() => find.descendant(
  of: find.byKey(ChatbotKeys.input),
  matching: find.byType(TextField),
);

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(_inputField(), text);
  await tester.tap(find.byKey(ChatbotKeys.send));
}

void main() {
  late FakeApiClient api;

  setUp(() => api = FakeApiClient());

  testWidgets('initial: the greeting and enabled quick prompts', (
    tester,
  ) async {
    await pumpApp(tester, const ChatbotScreen(), api: api);
    await tester.pumpAndSettle();

    expect(find.byKey(ChatbotKeys.message(0)), findsOneWidget);
    expect(find.byKey(ChatbotKeys.message(1)), findsNothing);
    expect(
      tester
          .widget<ActionChip>(find.byKey(ChatbotKeys.quickPrompt(0)))
          .onPressed,
      isNotNull,
    );
    expect(find.byKey(ChatbotKeys.error), findsNothing);
    expect(api.calls, isEmpty);
  });

  testWidgets('sending shows a spinner and disables input actions', (
    tester,
  ) async {
    api.stubFixture('POST', _path, _success);
    final gate = api.hold('POST', _path);

    await pumpApp(tester, const ChatbotScreen(), api: api);
    await _type(tester, 'Bánh sinh nhật');
    await tester.pump();

    expect(find.byKey(ChatbotKeys.sending), findsOneWidget);
    expect(find.byKey(ChatbotKeys.message(1)), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(ChatbotKeys.send)).onPressed,
      isNull,
    );
    expect(
      tester
          .widget<ActionChip>(find.byKey(ChatbotKeys.quickPrompt(0)))
          .onPressed,
      isNull,
    );

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(ChatbotKeys.sending), findsNothing);
  });

  testWidgets('a reply shows its text and suggested products', (tester) async {
    api.stubFixture('POST', _path, _success);
    final productId =
        ((_reply()['suggestedProducts'] as List).first as Map)['id'] as String;

    await pumpApp(tester, const ChatbotScreen(), api: api);
    await _type(tester, 'Gợi ý đồ uống');
    await tester.pumpAndSettle();

    expect(find.byKey(ChatbotKeys.message(2)), findsOneWidget);
    expect(find.text(_reply()['reply'] as String), findsOneWidget);
    expect(find.byKey(ChatbotKeys.suggestion(productId)), findsOneWidget);
    expect(tester.widget<TextField>(_inputField()).controller!.text, isEmpty);
  });

  testWidgets('an empty reply shows the fallback, no products', (tester) async {
    api.stubFixture('POST', _path, _empty);

    await pumpApp(tester, const ChatbotScreen(), api: api);
    await _type(tester, '?');
    await tester.pumpAndSettle();

    expect(find.byKey(ChatbotKeys.message(2)), findsOneWidget);
    expect(find.byType(SuggestedProductTile), findsNothing);
    expect(find.byKey(ChatbotKeys.error), findsNothing);
  });

  testWidgets('error shows the message; resending clears it', (tester) async {
    api.stubError('POST', _path);

    await pumpApp(tester, const ChatbotScreen(), api: api);
    await _type(tester, 'Hello');
    await tester.pumpAndSettle();

    expect(find.byKey(ChatbotKeys.error), findsOneWidget);
    expect(find.text(fixtureError(error500).message), findsOneWidget);

    api.stubFixture('POST', _path, _success);
    await tester.tap(find.byKey(ChatbotKeys.quickPrompt(0)));
    await tester.pumpAndSettle();

    expect(find.byKey(ChatbotKeys.error), findsNothing);
    expect(api.callsTo('POST', _path), hasLength(2));
  });
}
