import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/admin/shell/domain/admin_section.dart';
import 'package:bakery_mobile/src/features/admin/shell/presentation/screens/admin_placeholder_screen.dart';
import 'package:bakery_mobile/src/features/admin/shell/presentation/screens/admin_shell.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:bakery_mobile/src/features/navigation/presentation/screens/app_gate.dart';
import 'package:bakery_mobile/src/features/navigation/presentation/screens/app_shell.dart';
import 'package:bakery_mobile/src/features/onboarding/presentation/controllers/onboarding_view_model.dart';
import 'package:bakery_mobile/src/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake pattern như test/auth_view_model_test.dart: subclass + override.
class _FakeAdminAuthViewModel extends AuthViewModel {
  bool logoutCalled = false;

  @override
  AuthState build() => const AuthState(
    user: User(id: 'a-1', email: 'admin@bakery.vn', name: 'Hieu', role: 'ADMIN'),
  );

  @override
  Future<void> bootstrap() async {}

  @override
  Future<void> logout() async {
    logoutCalled = true;
    state = state.copyWith(clearUser: true);
  }
}

class _FakeCustomerAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(
    user: User(
      id: 'c-1',
      email: 'customer@bakery.vn',
      name: 'Long',
      role: 'CUSTOMER',
    ),
  );

  @override
  Future<void> bootstrap() async {}
}

class _FakeOnboardingViewModel extends OnboardingViewModel {
  _FakeOnboardingViewModel({this.hasSeenOnboarding = false});

  final bool hasSeenOnboarding;

  @override
  OnboardingState build() =>
      OnboardingState(hasSeenOnboarding: hasSeenOnboarding);

  @override
  Future<void> bootstrap() async {}
}

Future<void> _pumpAppGate(
  WidgetTester tester, {
  required AuthViewModel Function() createAuth,
  required OnboardingViewModel Function() createOnboarding,
  Key? scopeKey,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      // A distinct key per scenario forces Flutter to re-inflate the subtree
      // (same-type roots would reuse the element and keep the old container).
      key: scopeKey,
      overrides: [
        authViewModelProvider.overrideWith(createAuth),
        onboardingViewModelProvider.overrideWith(createOnboarding),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const AppGate()),
    ),
  );
  // AppGate runs its bootstrap in a postFrameCallback followed by a fixed
  // 1200ms delay — advance past the delay gate, then flush the gate frame.
  await tester.pump(const Duration(milliseconds: 1300));
  await tester.pump();
}

void main() {
  testWidgets('T1: ADMIN goes straight to AdminShell, never to onboarding', (
    tester,
  ) async {
    await _pumpAppGate(
      tester,
      createAuth: _FakeAdminAuthViewModel.new,
      createOnboarding: _FakeOnboardingViewModel.new,
    );

    expect(find.byType(AdminShell), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(MainLayout), findsNothing);
  });

  testWidgets('T2: CUSTOMER sees onboarding first, then MainLayout once seen', (
    tester,
  ) async {
    await _pumpAppGate(
      tester,
      createAuth: _FakeCustomerAuthViewModel.new,
      createOnboarding: _FakeOnboardingViewModel.new,
    );

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(MainLayout), findsNothing);
    expect(find.byType(AdminShell), findsNothing);

    // Same customer, onboarding already seen → customer MainLayout.
    await _pumpAppGate(
      tester,
      createAuth: _FakeCustomerAuthViewModel.new,
      createOnboarding: () =>
          _FakeOnboardingViewModel(hasSeenOnboarding: true),
      scopeKey: const ValueKey('customer-onboarding-seen'),
    );

    expect(find.byType(MainLayout), findsOneWidget);
    expect(find.byType(AdminShell), findsNothing);

    // Unmount the tree so the home tab's periodic banner timer is cancelled.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('T3: AdminShell drawer lists 15 sections in 5 groups and navigates', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light(), home: const AdminShell()),
      ),
    );

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // 15 section titles. 'Tổng quan' matches 3 widgets while the drawer is
    // open — the AppBar title (current section), the overview group header and
    // the dashboard item all carry the same pinned label; every other section
    // title is unique in this state.
    for (final section in AdminSection.values) {
      expect(
        find.text(section.vietnameseTitle),
        section == AdminSection.dashboard ? findsNWidgets(3) : findsOneWidget,
        reason: 'Drawer item missing: ${section.vietnameseTitle}',
      );
    }

    // 5 group headers, in web sidebar order ('Tổng quan' is covered above).
    for (final groupTitle in ['Bán hàng', 'Cửa hàng', 'Nội dung', 'Hệ thống']) {
      expect(
        find.text(groupTitle),
        findsOneWidget,
        reason: 'Drawer group header missing: $groupTitle',
      );
    }

    // 'Đơn hàng' has a real screen since phase 2 (it would hit the API here),
    // so navigation is exercised with a section that is still a placeholder.
    await tester.tap(find.text('Khách hàng'));
    await tester.pumpAndSettle();

    expect(find.byType(AdminPlaceholderScreen), findsOneWidget);
    expect(find.text('Mục "Khách hàng" sắp ra mắt'), findsOneWidget);
    expect(find.text('Khách hàng'), findsOneWidget);
  });

  testWidgets('T4: avatar popup menu logout calls AuthViewModel.logout', (
    tester,
  ) async {
    final fakeAuth = _FakeAdminAuthViewModel();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authViewModelProvider.overrideWith(() => fakeAuth)],
        child: MaterialApp(theme: AppTheme.light(), home: const AdminShell()),
      ),
    );

    await tester.tap(find.byKey(const Key('admin_shell_avatar')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();

    expect(fakeAuth.logoutCalled, isTrue);
  });
}
