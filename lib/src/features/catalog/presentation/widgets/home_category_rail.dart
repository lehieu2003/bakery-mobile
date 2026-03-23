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
      height: 92,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        children: [
          ...categories.map(
            (category) => _CategoryCapsule(
              label: category.name,
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
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 64,
          child: Column(
            children: [
              Container(
                width: 54,
                height: 82,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryPink
                      : const Color(0xFFD3D3D3),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 7),
                    ClipOval(
                      child: Container(
                        width: 34,
                        height: 34,
                        color: Colors.white.withValues(alpha: 0.68),
                        child: resolveImageUrl(imageUrl).isNotEmpty
                            ? Image.network(
                                resolveImageUrl(imageUrl),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              )
                            : null,
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
