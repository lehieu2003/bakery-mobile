import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/core/push/push_messaging.dart';
import 'package:bakery_mobile/src/features/notifications/application/services/push_registration_service.dart';
import 'package:bakery_mobile/src/features/notifications/data/datasources/device_token_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_api_client.dart';
import '../../helpers/fake_push_messaging.dart';

const _path = '/api/notifications/device-token';

void main() {
  late FakeApiClient api;
  late FakePushMessaging push;
  late PushRegistrationService service;

  setUp(() {
    api = FakeApiClient()
      ..stub('POST', _path, (_) => {'id': 'dt-1'})
      ..stub('DELETE', _path, (_) => {'revoked': 1});
    push = FakePushMessaging();
    service = PushRegistrationService(
      messaging: push,
      api: DeviceTokenApiService(api),
      platform: 'android',
    );
  });

  Map<String, Object?> body(ApiCall call) => call.body! as Map<String, Object?>;

  test('sign-in joins announcements and registers the token', () async {
    await service.register();

    expect(push.topics, ['announcements']);
    expect(push.permissionRequests, 1);
    final calls = api.callsTo('POST', _path);
    expect(calls, hasLength(1));
    expect(body(calls.single), {'token': 'token-1', 'platform': 'android'});
  });

  test('no token is sent when notifications are not allowed', () async {
    push.allowNotifications = false;

    await service.register();

    expect(push.topics, ['announcements']);
    expect(api.callsTo('POST', _path), isEmpty);
  });

  test('a rotated token is registered again', () async {
    await service.register();
    push.rotateToken('token-2');
    await pumpEventQueue();

    expect(api.callsTo('POST', _path).map((c) => body(c)['token']), [
      'token-1',
      'token-2',
    ]);
  });

  test('a token still tied to a previous account is replaced', () async {
    var first = true;
    api.stub('POST', _path, (_) {
      if (first) {
        first = false;
        throw ApiException('owned', statusCode: 409);
      }
      return {'id': 'dt-2'};
    });

    await service.register();

    expect(push.deletedTokens, 1);
    expect(api.callsTo('POST', _path).map((c) => body(c)['token']), [
      'token-1',
      'token-fresh',
    ]);
  });

  test('server errors never reach the caller', () async {
    api.stubError('POST', _path);
    await expectLater(service.register(), completes);
  });

  test('sign-out revokes the registered token, then stops tracking', () async {
    await service.register();
    await service.unregister();

    final revoked = api.callsTo('DELETE', _path);
    expect(revoked, hasLength(1));
    expect(body(revoked.single), {'token': 'token-1'});

    push.rotateToken('token-3');
    await pumpEventQueue();
    expect(api.callsTo('POST', _path), hasLength(1));
  });

  test('without Firebase nothing is sent', () async {
    final off = PushRegistrationService(
      messaging: const DisabledPushMessaging(),
      api: DeviceTokenApiService(api),
    );

    await off.register();
    await off.unregister();

    expect(api.calls, isEmpty);
  });
}
