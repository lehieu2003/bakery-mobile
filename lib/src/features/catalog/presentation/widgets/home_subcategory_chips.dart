import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/category.dart';

class HomeSubcategoryChips extends StatelessWidget {
  const HomeSubcategoryChips({
    super.key,
    required this.subCategories,
    required this.selectedCategoryId,
    required this.onSelect,
  });

  final List<Category> subCategories;
  final String? selectedCategoryId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    if (subCategories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Danh Mục Con',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.inkBrown,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            scrollDirection: Axis.horizontal,
            children: subCategories
                .map(
                  (subcategory) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      backgroundColor: AppTheme.surfaceCream,
                      selectedColor: AppTheme.peachTint,
                      checkmarkColor: AppTheme.warmBrown,
                      side: BorderSide(
                        color: selectedCategoryId == subcategory.id
                            ? AppTheme.pastryPeach.withValues(alpha: 0.65)
                            : AppTheme.outlineBeige,
                      ),
                      label: Text(
                        subcategory.children.isNotEmpty
                            ? '${subcategory.name} (${subcategory.children.length})'
                            : subcategory.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      selected: selectedCategoryId == subcategory.id,
                      onSelected: (_) => onSelect(subcategory.id),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
