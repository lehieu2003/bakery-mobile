import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom-bar tabs of the customer shell, in bar order.
abstract final class MainTab {
  static const int home = 0;
  static const int search = 1;
  static const int wishlist = 2;
  static const int account = 3;
}

/// The selected tab of `MainLayout`, so a screen pushed above the shell
/// (checkout) can send the user back to a given tab. Lives as long as the
/// shell watches it: a new sign-in starts on [MainTab.home] again.
class MainTabController extends AutoDisposeNotifier<int> {
  @override
  int build() => MainTab.home;

  void select(int tab) => state = tab;
}
