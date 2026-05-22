import 'package:shared_preferences/shared_preferences.dart';

class OnboardingStorage {
  static const _seenKey = 'bakery_onboarding_seen';

  Future<bool> readHasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }
}
