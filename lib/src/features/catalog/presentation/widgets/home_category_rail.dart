import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/core/utils/image_url.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/category.dart';

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
    if (words.length <= 2) return name.trim();
    return words.take(2).join(' ');
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
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: 72,
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFEFE6) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.blushPink.withValues(alpha: 0.55)
                      : const Color(0xFFFFF8F0),
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
                child: resolveImageUrl(imageUrl).isNotEmpty
                    ? Image.network(
                        resolveImageUrl(imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.bakery_dining_outlined,
                          color: AppTheme.warmBrown,
                          size: 24,
                        ),
                      )
                    : const Icon(
                        Icons.bakery_dining_outlined,
                        color: AppTheme.warmBrown,
                        size: 24,
                      ),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.warmBrown
                      : const Color(0xFF76665C),
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
