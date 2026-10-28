import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/navigation/app_navigator.dart';
import 'package:bakery_mobile/src/core/push/push_messaging.dart';
import 'package:bakery_mobile/src/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:bakery_mobile/src/features/orders/presentation/screens/order_detail_screen.dart';

/// Wires push notifications to the app, above the navigator
/// (`MaterialApp.builder`):
/// - registers this phone for the signed-in account, forgets it on sign-out;
/// - while the app is open, shows the push as a snack bar and refreshes the
///   notification list;
/// - a tapped push opens its order, or the notification list.
class PushNotificationsHost extends ConsumerStatefulWidget {
  const PushNotificationsHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushNotificationsHost> createState() =>
      _PushNotificationsHostState();
}

class _PushNotificationsHostState extends ConsumerState<PushNotificationsHost> {
  final List<StreamSubscription<PushMessage>> _subscriptions = [];
  bool _handledLaunchMessage = false;

  @override
  void initState() {
    super.initState();
    final messaging = ref.read(pushMessagingProvider);
    _subscriptions
      ..add(messaging.onForegroundMessage.listen(_showForeground))
      ..add(messaging.onMessageOpenedApp.listen(_open));
    // A session restored on start counts as signing in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(authViewModelProvider).user != null) _onSignedIn();
    });
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  Future<void> _onSignedIn() async {
    await ref.read(pushRegistrationServiceProvider).register();
    if (_handledLaunchMessage || !mounted) return;
    _handledLaunchMessage = true;
    final launch = await ref.read(pushMessagingProvider).getInitialMessage();
    if (launch != null && mounted) _open(launch);
  }

  void _showForeground(PushMessage message) {
    if (ref.read(authViewModelProvider).user == null) return;
    unawaited(ref.read(notificationsViewModelProvider.notifier).load());
    final text = [
      message.title,
      message.body,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(': ');
    if (text.isEmpty) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text, maxLines: 3, overflow: TextOverflow.ellipsis),
          action: SnackBarAction(label: 'Xem', onPressed: () => _open(message)),
        ),
      );
  }

  void _open(PushMessage message) {
    final user = ref.read(authViewModelProvider).user;
    final navigator = appNavigatorKey.currentState;
    if (user == null || navigator == null) return;
    final orderNumber = message.orderNumber;
    // Order updates go to the customer's own order; admins (and other
    // pushes) land on the notification list.
    final Widget screen = orderNumber != null && user.role != 'ADMIN'
        ? OrderDetailScreen(orderNumber: orderNumber)
        : const NotificationsScreen();
    navigator.push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authViewModelProvider.select((state) => state.user?.id), (
      previous,
      next,
    ) {
      if (next == previous) return;
      if (next != null) {
        unawaited(_onSignedIn());
      } else {
        ref.read(pushRegistrationServiceProvider).forget();
      }
    });
    return widget.child;
  }
}
