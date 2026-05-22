import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';

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
        14,
        MediaQuery.paddingOf(context).top + 8,
        14,
        16,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFDEE7), Color(0xFFFFE6CF)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(38)),
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
                onTap: onCartTap,
              ),
              const SizedBox(width: 10),
              Badge(
                isLabelVisible: favoriteCount > 0,
                label: Text('$favoriteCount'),
                child: _HeaderSquareButton(
                  icon: Icons.favorite_border_rounded,
                  onTap: onFavoriteTap,
                ),
              ),
              const SizedBox(width: 10),
              Badge(
                isLabelVisible: unreadCount > 0,
                label: Text('$unreadCount'),
                child: _HeaderSquareButton(
                  icon: Icons.notifications_none_rounded,
                  onTap: onNotificationTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: onSearchTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: double.infinity,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.74),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.warmBrown.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: const Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 19,
                    color: Color(0xFF9B8474),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Search fresh pastry',
                    style: TextStyle(
                      color: Color(0xFF9B8474),
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

class _HeaderSquareButton extends StatelessWidget {
  const _HeaderSquareButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.52),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: AppTheme.warmBrown, size: 21),
        ),
      ),
    );
  }
}
