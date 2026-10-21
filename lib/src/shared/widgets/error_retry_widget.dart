import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';

/// Failure state with a 'Thử lại' action.
///
/// Default: centered icon, optional [title], [message] and a filled retry
/// button (plus an optional [secondaryAction] below it) — for a screen or
/// section that has nothing else to show. [compact]: the message in the
/// error color and a text button, for a failure inline below existing
/// content (e.g. a list footer).
class ErrorRetryWidget extends StatelessWidget {
  const ErrorRetryWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.title,
    this.icon = Icons.error_outline_rounded,
    this.secondaryAction,
    this.compact = false,
  });

  final String message;

  /// Hides the retry button when null.
  final VoidCallback? onRetry;
  final String? title;
  final IconData icon;
  final Widget? secondaryAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final retry = onRetry;

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            if (retry != null)
              TextButton(onPressed: retry, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    final heading = title;
    final secondary = secondaryAction;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppTheme.warmBrown),
            const SizedBox(height: 12),
            if (heading != null) ...[
              Text(
                heading,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (retry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: retry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
            if (secondary != null) ...[const SizedBox(height: 8), secondary],
          ],
        ),
      ),
    );
  }
}
