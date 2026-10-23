import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the device has a network connection. Online until told otherwise:
/// only [ConnectivityWatcher] (mounted at the app root) updates it, so
/// widget tests never touch the platform plugin and stay "online".
///
/// A connection is not proof the server is reachable (captive Wi‑Fi), so
/// this drives the offline banner and auto-retry, while request failures
/// are still judged by their [ApiErrorKind].
final isOnlineProvider = StateProvider<bool>((ref) => true);

/// Feeds [isOnlineProvider] from `connectivity_plus` for as long as it is
/// mounted.
class ConnectivityWatcher extends ConsumerStatefulWidget {
  const ConnectivityWatcher({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ConnectivityWatcher> createState() =>
      _ConnectivityWatcherState();
}

class _ConnectivityWatcherState extends ConsumerState<ConnectivityWatcher> {
  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = _connectivity.onConnectivityChanged.listen(
      _update,
      // A platform without the plugin keeps the "online" default.
      onError: (Object _) {},
    );
    _connectivity.checkConnectivity().then(_update, onError: (Object _) {});
  }

  void _update(List<ConnectivityResult> results) {
    if (!mounted) return;
    ref.read(isOnlineProvider.notifier).state = results.any(
      (result) => result != ConnectivityResult.none,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
