import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/category.dart';
import 'package:bakery_mobile/src/shared/widgets/app_network_image_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

/// Category labels under the round icons are cut to this many words.
const int _maxLabelWords = 2;

class HomeCategoryRail extends StatelessWidget {
  const HomeCategoryRail({
    super.key,
    required this.categories,
    required this.onSelect,
  });

  final List<Category> categories;

  /// Opens the tapped category (the home screen pushes its product list).
  final ValueChanged<Category> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        children: [
          ...categories.map(
            (category) => _CategoryCapsule(
              label: _shortCategoryLabel(category.name),
              imageUrl: category.imageUrl,
              onTap: () => onSelect(category),
            ),
          ),
        ],
      ),
    );
  }

  String _shortCategoryLabel(String name) {
    final normalized = name.trim().toLowerCase();
    if (normalized.contains('pha') || normalized.contains('drink')) {
      return 'Đồ uống';
    }
    if (normalized.contains('làm') ||
        normalized.contains('lam') ||
        normalized.contains('baking')) {
      return 'Làm bánh';
    }
    if (normalized.contains('birthday') || normalized.contains('sinh')) {
      return 'Sinh nhật';
    }
    if (normalized.contains('tiramisu')) {
      return 'Tiramisu';
    }

    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length <= _maxLabelWords) return name.trim();
    return words.take(_maxLabelWords).join(' ');
  }
}

class _CategoryCapsule extends StatelessWidget {
  const _CategoryCapsule({
    required this.label,
    required this.imageUrl,
    required this.onTap,
  });

  final String label;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        child: Container(
          width: 72,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceRailIcon,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.warmBrown.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: AppNetworkImageWidget(
                  url: imageUrl,
                  backgroundColor: Colors.transparent,
                  emptyIcon: Icons.bakery_dining_outlined,
                  errorIcon: Icons.bakery_dining_outlined,
                  iconSize: 24,
                  iconColor: AppTheme.warmBrown,
                ),
              ),
              const Gap(AppSpacing.sm),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  height: 1.08,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
