import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/network/connectivity.dart';
import 'package:bakery_mobile/src/core/theme/app_durations.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

/// App-wide strip shown above every screen while the device is offline;
/// it collapses to nothing once the connection is back.
/// Matches the banner's small body text.
const double _iconSize = 18;

class OfflineBannerWidget extends ConsumerWidget {
  const OfflineBannerWidget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        AnimatedSize(
          duration: AppDurations.fast,
          child: isOnline
              ? const SizedBox(width: double.infinity)
              : Material(
                  color: colors.inverseSurface,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: _iconSize,
                            color: colors.onInverseSurface,
                          ),
                          const Gap(AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Mất kết nối mạng — một số chức năng tạm thời không dùng được.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.onInverseSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        Expanded(
          // The banner already pads for the status bar.
          child: MediaQuery.removePadding(
            context: context,
            removeTop: !isOnline,
            child: child,
          ),
        ),
      ],
    );
  }
}
