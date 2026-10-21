import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/category.dart';
import 'package:bakery_mobile/src/shared/widgets/app_network_image_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_durations.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';

/// Category labels under the round icons are cut to this many words.
const int _maxLabelWords = 2;

/// Circle behind an unselected category icon.
const Color _railIconBackground = Color(0xFFFFF8F0);

class HomeCategoryRail extends StatelessWidget {
  const HomeCategoryRail({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelect,
  });

  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          ...categories.map(
            (category) => _CategoryCapsule(
              label: _shortCategoryLabel(category.name),
              imageUrl: category.imageUrl,
              isSelected: _isRootSelected(category, selectedCategoryId),
              onTap: () => onSelect(category.id),
            ),
          ),
        ],
      ),
    );
  }

  bool _isRootSelected(Category root, String? selectedId) {
    if (selectedId == null) return false;
    if (root.id == selectedId) return true;
    return _contains(root.children, selectedId);
  }

  bool _contains(List<Category> children, String selectedId) {
    for (final category in children) {
      if (category.id == selectedId) return true;
      if (_contains(category.children, selectedId)) return true;
    }
    return false;
  }

  String _shortCategoryLabel(String name) {
    final normalized = name.trim().toLowerCase();
    if (normalized.contains('pha') || normalized.contains('drink')) {
      return 'Drinks';
    }
    if (normalized.contains('làm') ||
        normalized.contains('lam') ||
        normalized.contains('baking')) {
      return 'Baking';
    }
    if (normalized.contains('birthday') || normalized.contains('sinh')) {
      return 'Birthday';
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
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String? imageUrl;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: Curves.easeOut,
          width: 72,
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.peachTint : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.xxxl),
          ),
          child: Column(
            children: [
              AnimatedContainer(
                duration: AppDurations.fast,
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.blushPink.withValues(alpha: 0.55)
                      : _railIconBackground,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.warmBrown.withValues(
                        alpha: isSelected ? 0.12 : 0.06,
                      ),
                      blurRadius: isSelected ? 14 : 10,
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
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? AppTheme.warmBrown : AppTheme.textMuted,
                  fontSize: 11,
                  height: 1.08,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
