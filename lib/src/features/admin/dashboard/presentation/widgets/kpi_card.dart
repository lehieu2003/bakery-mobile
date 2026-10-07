import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';

/// One tile of the dashboard's KPI grid: a [Card] (theme from AppTheme) with a
/// muted [label] on top and the bold [value] beneath. [child] optionally
/// renders extra content below the value — e.g. the per-status pill rows of
/// the 'Trạng thái đơn' card; pass an empty [value] to hide the number line.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.child,
  });

  final String label;
  final String value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (value.isNotEmpty) ...[
              const SizedBox(height: 6),
              // FittedBox shrinks long values (e.g. '1.250.000 ₫' on narrow
              // phones) instead of clipping them.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.inkBrown,
                  ),
                ),
              ),
            ],
            if (child != null) ...[const SizedBox(height: 8), child!],
          ],
        ),
      ),
    );
  }
}
