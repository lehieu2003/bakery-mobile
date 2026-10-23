import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/network/connectivity.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

/// Failure state with a 'Thử lại' action.
///
/// Default: centered icon, optional [title], [message] and a filled retry
/// button (plus an optional [secondaryAction] below it) — for a screen or
/// section that has nothing else to show. [compact]: the message in the
/// error color and a text button, for a failure inline below existing
/// content (e.g. a list footer).
///
/// Connectivity-aware: while the device is offline the default layout shows
/// a wifi-off icon and "Mất kết nối" title, and when the connection comes
/// back [onRetry] runs by itself — every screen using this widget reloads
/// without the user tapping.
class ErrorRetryWidget extends ConsumerWidget {
  const ErrorRetryWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.title,
    this.icon = Icons.error_outline_rounded,
    this.secondaryAction,
    this.compact = false,
  });

  /// Key of the 'Thử lại' button (both layouts) — for tests and finders.
  static const Key retryButtonKey = Key('error_retry.retry');

  final String message;

  /// Hides the retry button when null.
  final VoidCallback? onRetry;
  final String? title;
  final IconData icon;
  final Widget? secondaryAction;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final retry = onRetry;
    final isOnline = ref.watch(isOnlineProvider);
    ref.listen<bool>(isOnlineProvider, (wasOnline, nowOnline) {
      if (wasOnline == false && nowOnline) retry?.call();
    });

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            if (retry != null)
              TextButton(
                key: retryButtonKey,
                onPressed: retry,
                child: const Text('Thử lại'),
              ),
          ],
        ),
      );
    }

    final heading = title ?? (isOnline ? null : 'Mất kết nối');
    final secondary = secondaryAction;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOnline ? icon : Icons.wifi_off_rounded,
              size: 44,
              color: AppTheme.warmBrown,
            ),
            const Gap(AppSpacing.md),
            if (heading != null) ...[
              Text(
                heading,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(AppSpacing.sm),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (retry != null) ...[
              const Gap(AppSpacing.lg),
              FilledButton.icon(
                key: retryButtonKey,
                onPressed: retry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
            if (secondary != null) ...[const Gap(AppSpacing.sm), secondary],
          ],
        ),
      ),
    );
  }
}
