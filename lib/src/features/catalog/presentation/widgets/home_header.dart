import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.unreadCount,
    required this.onMenuTap,
    required this.onCartTap,
    required this.onNotificationTap,
    required this.onSearchTap,
  });

  final int unreadCount;
  final VoidCallback onMenuTap;
  final VoidCallback onCartTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        MediaQuery.paddingOf(context).top + 10,
        14,
        20,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.primaryPink,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(56)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onMenuTap,
                icon: const Icon(
                  Icons.menu_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const Spacer(),
              _HeaderSquareButton(
                icon: Icons.shopping_cart_outlined,
                onTap: onCartTap,
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
          const SizedBox(height: 14),
          InkWell(
            onTap: onSearchTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: double.infinity,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.76),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Icon(Icons.search_rounded, color: Color(0xFF8C8C8C)),
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
      color: Colors.white.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}
