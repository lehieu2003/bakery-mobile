import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_radius.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/shared/utils/order_status_display.dart';

const double _dotSize = 28;
const double _lineThickness = 2;
const double _currentRingWidth = 4;
const double _checkSize = 16;

/// Step progress bar of an order (see [orderProgressSteps]): reached steps
/// are ticked, the current one is ringed. A cancelled order shows a notice
/// instead; an unknown status shows nothing.
class OrderStatusStepper extends StatelessWidget {
  const OrderStatusStepper({super.key, required this.status});

  final String status;

  static Key stepKey(String status) => Key('order-step.$status');

  @override
  Widget build(BuildContext context) {
    if (status.trim().toUpperCase() == 'CANCELLED') {
      return const _CancelledNotice();
    }
    final current = orderProgressIndex(status);
    if (current < 0) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < orderProgressSteps.length; i++)
          Expanded(
            child: _Step(
              key: stepKey(orderProgressSteps[i].status),
              number: i + 1,
              label: orderProgressSteps[i].label,
              done: i <= current,
              isCurrent: i == current,
              lineBefore: i == 0 ? null : i <= current,
              lineAfter: i == orderProgressSteps.length - 1
                  ? null
                  : i + 1 <= current,
            ),
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    super.key,
    required this.number,
    required this.label,
    required this.done,
    required this.isCurrent,
    required this.lineBefore,
    required this.lineAfter,
  });

  final int number;
  final String label;
  final bool done;
  final bool isCurrent;

  /// Whether the connector on each side is reached; null = no connector.
  final bool? lineBefore;
  final bool? lineAfter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget line(bool? reached) => Expanded(
      child: Container(
        height: _lineThickness,
        color: reached == null
            ? Colors.transparent
            : reached
            ? AppTheme.primaryPink
            : AppTheme.outlineBeige,
      ),
    );

    return Semantics(
      label: '$label${done ? ', đã xong' : ''}',
      selected: isCurrent,
      excludeSemantics: true,
      child: Column(
        children: [
          Row(
            children: [
              line(lineBefore),
              Container(
                width: _dotSize,
                height: _dotSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppTheme.primaryPink : AppTheme.surfaceWhite,
                  border: Border.all(
                    color: done ? AppTheme.primaryPink : AppTheme.outlineBeige,
                    width: _lineThickness,
                  ),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryPink.withValues(alpha: 0.2),
                            spreadRadius: _currentRingWidth,
                          ),
                        ]
                      : null,
                ),
                child: done
                    ? const Icon(
                        Icons.check_rounded,
                        size: _checkSize,
                        color: Colors.white,
                      )
                    : Text(
                        '$number',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              line(lineAfter),
            ],
          ),
          const Gap(AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: textTheme.labelSmall?.copyWith(
                color: done ? scheme.onSurface : AppTheme.textMuted,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelledNotice extends StatelessWidget {
  const _CancelledNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppTheme.statusCancelledBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cancel_outlined,
            color: AppTheme.statusCancelledText,
          ),
          const Gap(AppSpacing.sm),
          Text(
            'Đơn hàng đã huỷ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.statusCancelledText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
