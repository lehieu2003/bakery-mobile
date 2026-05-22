import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/features/navigation/presentation/screens/app_shell.dart';
import 'package:bakery_mobile/src/features/navigation/presentation/screens/auth_layout.dart';
import 'package:bakery_mobile/src/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:bakery_mobile/src/features/onboarding/presentation/screens/splash_screen.dart';

class AppGate extends ConsumerStatefulWidget {
  const AppGate({super.key});

  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate> {
  bool _gateReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      ref.read(authViewModelProvider.notifier).bootstrap(),
      ref.read(onboardingViewModelProvider.notifier).bootstrap(),
      Future<void>.delayed(const Duration(milliseconds: 1200)),
    ]);
    if (!mounted) return;
    setState(() => _gateReady = true);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final onboardingState = ref.watch(onboardingViewModelProvider);

    if (!_gateReady ||
        authState.isBootstrapping ||
        onboardingState.isBootstrapping) {
      return const SplashScreen();
    }

    if (!onboardingState.hasSeenOnboarding) {
      return OnboardingScreen(
        onComplete: ref.read(onboardingViewModelProvider.notifier).complete,
      );
    }

    if (authState.isAuthenticated) {
      return const MainLayout();
    }

    return const AuthLayout();
  }
}
