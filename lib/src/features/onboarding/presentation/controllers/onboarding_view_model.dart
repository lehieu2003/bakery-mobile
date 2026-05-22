import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';

class OnboardingState {
  const OnboardingState({
    this.isBootstrapping = false,
    this.hasSeenOnboarding = false,
  });

  final bool isBootstrapping;
  final bool hasSeenOnboarding;

  OnboardingState copyWith({bool? isBootstrapping, bool? hasSeenOnboarding}) {
    return OnboardingState(
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
    );
  }
}

class OnboardingViewModel extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  Future<void> bootstrap() async {
    state = state.copyWith(isBootstrapping: true);
    try {
      final hasSeen = await ref
          .read(onboardingStorageProvider)
          .readHasSeenOnboarding();
      state = state.copyWith(
        hasSeenOnboarding: hasSeen,
        isBootstrapping: false,
      );
    } catch (_) {
      state = state.copyWith(hasSeenOnboarding: false, isBootstrapping: false);
    }
  }

  Future<void> complete() async {
    await ref.read(onboardingStorageProvider).markOnboardingSeen();
    state = state.copyWith(hasSeenOnboarding: true);
  }
}
