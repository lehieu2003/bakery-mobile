import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_api_client.dart';
import '../../helpers/fixture.dart';
import '../../helpers/pump_app.dart';

const _path = '/api/chat';
const _success = 'chatbot/chat_success.json';
const _empty = 'chatbot/chat_empty.json';

Map<String, dynamic> _reply() => fixtureData(_success) as Map<String, dynamic>;

void main() {
  late FakeApiClient api;

  setUp(() => api = FakeApiClient());

  test('initial state holds only the assistant greeting', () {
    final state = makeContainer(api).read(chatbotViewModelProvider);

    expect(state.messages.single.role, 'assistant');
    expect(state.isSending, isFalse);
    expect(state.error, isNull);
    expect(api.calls, isEmpty);
  });

  test(
    'sending → success: user message, then the reply with products',
    () async {
      api.stubFixture('POST', _path, _success);
      final gate = api.hold('POST', _path);
      final container = makeContainer(api);
      final vm = container.read(chatbotViewModelProvider.notifier);

      final sending = vm.send('  Bánh sinh nhật  ');
      var state = container.read(chatbotViewModelProvider);
      expect(state.isSending, isTrue);
      expect(state.messages.last.role, 'user');
      expect(state.messages.last.content, 'Bánh sinh nhật');
      gate.complete();
      await sending;

      state = container.read(chatbotViewModelProvider);
      expect(state.isSending, isFalse);
      expect(state.error, isNull);
      expect(state.messages, hasLength(3));
      expect(state.messages.last.role, 'assistant');
      expect(state.messages.last.content, _reply()['reply']);
      expect(
        state.messages.last.suggestedProducts.map((p) => p.id),
        (_reply()['suggestedProducts'] as List).map((p) => (p as Map)['id']),
      );
    },
  );

  test('request carries the message and the history so far', () async {
    api.stubFixture('POST', _path, _success);
    final container = makeContainer(api);

    await container.read(chatbotViewModelProvider.notifier).send('Xin chào');

    final body = api.callsTo('POST', _path).single.body as Map;
    expect(body['message'], 'Xin chào');
    expect(body['history'], [
      {'role': 'assistant', 'content': isA<String>()},
      {'role': 'user', 'content': 'Xin chào'},
    ]);
  });

  test('sending → empty reply: a fallback answer, no error', () async {
    api.stubFixture('POST', _path, _empty);
    final container = makeContainer(api);

    await container.read(chatbotViewModelProvider.notifier).send('?');

    final state = container.read(chatbotViewModelProvider);
    expect(state.error, isNull);
    expect(state.messages.last.role, 'assistant');
    expect(state.messages.last.content, isNotEmpty);
    expect(state.messages.last.suggestedProducts, isEmpty);
  });

  test('sending → error: a system answer plus the API message', () async {
    api.stubError('POST', _path);
    final container = makeContainer(api);

    await container.read(chatbotViewModelProvider.notifier).send('Hello');

    final state = container.read(chatbotViewModelProvider);
    expect(state.isSending, isFalse);
    expect(state.error, fixtureError(error500).message);
    expect(state.messages, hasLength(3));
    expect(state.messages.last.role, 'assistant');
  });

  test('the next send clears a previous error', () async {
    api.stubError('POST', _path);
    final container = makeContainer(api);
    final vm = container.read(chatbotViewModelProvider.notifier);
    await vm.send('Hello');
    api.stubFixture('POST', _path, _success);

    await vm.send('Again');

    expect(container.read(chatbotViewModelProvider).error, isNull);
  });

  test('blank input and sends while busy are ignored', () async {
    api.stubFixture('POST', _path, _success);
    final gate = api.hold('POST', _path);
    final container = makeContainer(api);
    final vm = container.read(chatbotViewModelProvider.notifier);

    await vm.send('   ');
    final first = vm.send('One');
    await vm.send('Two');
    gate.complete();
    await first;

    expect(api.callsTo('POST', _path), hasLength(1));
    expect(container.read(chatbotViewModelProvider).messages, hasLength(3));
  });
}
