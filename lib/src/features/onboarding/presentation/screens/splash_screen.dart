import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/core/theme/app_durations.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

/// Rounded tray under the splash pastry mark.
const double _trayRadius = 26;

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasCream,
      body: SafeArea(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.88, end: 1),
            duration: AppDurations.slow,
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: ((value - 0.88) / 0.12).clamp(0, 1),
                child: Transform.scale(scale: value, child: child),
              );
            },
            child: const _SplashMark(),
          ),
        ),
      ),
    );
  }
}

class _SplashMark extends StatelessWidget {
  const _SplashMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.surfaceCream,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.warmBrown.withValues(alpha: 0.16),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: const SizedBox(
            width: 112,
            height: 112,
            child: Center(child: _BreadIcon()),
          ),
        ),
        const Gap(AppSpacing.xxl),
        const Text(
          'BAKERY SHOP',
          style: TextStyle(
            color: AppTheme.inkBrown,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const Gap(AppSpacing.sm),
        const Text(
          'Bánh ngon cho mỗi ngày',
          style: TextStyle(
            color: AppTheme.warmBrown,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BreadIcon extends StatelessWidget {
  const _BreadIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 62,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.pastryPeach,
            borderRadius: BorderRadius.circular(AppRadius.sheet),
            border: Border.all(color: AppTheme.warmBrown, width: 2),
          ),
        ),
        Positioned(
          top: 30,
          child: Container(
            width: 74,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.blushPink,
              borderRadius: BorderRadius.circular(_trayRadius),
              border: Border.all(color: AppTheme.warmBrown, width: 2),
            ),
          ),
        ),
        const Positioned(top: 22, left: 36, child: _Crumb()),
        const Positioned(top: 22, right: 36, child: _Crumb()),
        const Positioned(top: 47, child: _Crumb()),
      ],
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCream,
        shape: BoxShape.circle,
      ),
    );
  }
}
