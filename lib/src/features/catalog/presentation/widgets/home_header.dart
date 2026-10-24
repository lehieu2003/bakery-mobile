import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

/// Bottom curve of the home header.
const double _headerCurveRadius = 38;

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.unreadCount,
    required this.favoriteCount,
    required this.onMenuTap,
    required this.onCartTap,
    required this.onNotificationTap,
    required this.onFavoriteTap,
    required this.onSearchTap,
  });

  final int unreadCount;
  final int favoriteCount;
  final VoidCallback onMenuTap;
  final VoidCallback onCartTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        MediaQuery.paddingOf(context).top + AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.headerGradientStart, AppTheme.headerGradientEnd],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(_headerCurveRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.pastryPeach.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Mở menu',
                onPressed: onMenuTap,
                icon: const Icon(
                  Icons.menu_rounded,
                  color: AppTheme.warmBrown,
                  size: 30,
                ),
              ),
              const Spacer(),
              _HeaderSquareButton(
                icon: Icons.shopping_cart_outlined,
                label: 'Giỏ hàng',
                onTap: onCartTap,
              ),
              const Gap(AppSpacing.md),
              Badge(
                isLabelVisible: favoriteCount > 0,
                label: Text('$favoriteCount'),
                child: _HeaderSquareButton(
                  icon: Icons.favorite_border_rounded,
                  label: favoriteCount > 0
                      ? 'Yêu thích, $favoriteCount sản phẩm'
                      : 'Yêu thích',
                  onTap: onFavoriteTap,
                ),
              ),
              const Gap(AppSpacing.md),
              Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: _HeaderSquareButton(
                  icon: Icons.notifications_none_rounded,
                  label: unreadCount > 0
                      ? 'Thông báo, $unreadCount chưa đọc'
                      : 'Thông báo',
                  onTap: onNotificationTap,
                ),
              ),
            ],
          ),
          const Gap(AppSpacing.md),
          InkWell(
            onTap: onSearchTap,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              width: double.infinity,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.surfaceSearchBar,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.warmBrown.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: const Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 19,
                    color: AppTheme.textHint,
                  ),
                  Gap(AppSpacing.sm),
                  Text(
                    'Tìm bánh tươi ngon…',
                    style: TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Material's minimum touch target.
const double _minTapSize = 48;

class _HeaderSquareButton extends StatelessWidget {
  const _HeaderSquareButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;

  /// Spoken by screen readers and shown on long press; includes any count
  /// the badge shows, since the badge itself is not announced.
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: label,
        onTap: onTap,
        excludeSemantics: true,
        child: Material(
          color: AppTheme.surfaceHeaderButton,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: _minTapSize,
              height: _minTapSize,
              child: Icon(icon, color: AppTheme.warmBrown, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
