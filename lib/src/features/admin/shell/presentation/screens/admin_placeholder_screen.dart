import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';

/// Root screen for every admin section until its phase ships: a themed
/// "coming soon" panel in the middle of the screen.
class AdminPlaceholderScreen extends StatelessWidget {
  const AdminPlaceholderScreen(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.construction_outlined,
              size: 56,
              color: AppTheme.warmBrown.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 16),
            Text(
              'Mục "$title" sắp ra mắt',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.inkBrown,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
