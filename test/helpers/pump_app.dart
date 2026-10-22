import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_api_client.dart';

const testCustomer = User(
  id: 'cmm9b9k110001uyzsm6xhx6x4',
  email: 'customer@bakery.test',
  name: 'Linh Nguyen',
  role: 'CUSTOMER',
);

/// Auth with a fixed session — no token storage, no `/api/auth/me`.
class FakeAuthViewModel extends AuthViewModel {
  FakeAuthViewModel({this.user = testCustomer});

  final User? user;

  @override
  AuthState build() => AuthState(user: user);

  @override
  Future<void> bootstrap() async {}

  @override
  Future<void> logout() async => state = const AuthState();
}

/// Overrides wiring [api] under every service, plus a signed-in customer
/// (pass `signedIn: false` for a guest).
List<Override> testOverrides(
  FakeApiClient api, {
  bool signedIn = true,
  List<Override> extra = const [],
}) => [
  apiClientProvider.overrideWithValue(api),
  authViewModelProvider.overrideWith(
    () => FakeAuthViewModel(user: signedIn ? testCustomer : null),
  ),
  ...extra,
];

/// Container for view-model unit tests; disposed automatically.
ProviderContainer makeContainer(
  FakeApiClient api, {
  bool signedIn = true,
  List<Override> extra = const [],
}) {
  final container = ProviderContainer(
    overrides: testOverrides(api, signedIn: signedIn, extra: extra),
  );
  addTearDown(container.dispose);
  return container;
}

/// Pumps [child] as the home of a themed [MaterialApp] inside a
/// [ProviderScope] backed by [api]. No localization delegates: the app has
/// no l10n yet.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  required FakeApiClient api,
  bool signedIn = true,
  List<Override> extra = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(api, signedIn: signedIn, extra: extra),
      child: MaterialApp(theme: AppTheme.light(), home: child),
    ),
  );
}
