import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/features/admin/products/domain/models/admin_product.dart';
import 'package:bakery_mobile/src/features/admin/products/presentation/controllers/product_form_view_model.dart';

/// Attribute filter chips of the product form. SELECT attributes behave
/// radio-style (one pick), MULTI_SELECT toggle membership.
class ProductAttributesSection extends ConsumerWidget {
  const ProductAttributesSection({super.key, this.productId});

  final String? productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productFormViewModelProvider(productId));

    return FutureBuilder<List<AdminAttribute>>(
      future: ref.read(productsAdminRepositoryProvider).getAttributes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final attributes = snapshot.data!;
        if (attributes.isEmpty) {
          return Text(
            'Chưa có bộ lọc nào',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final attribute in attributes) ...[
              Text(
                attribute.name,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const Gap(AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final value in attribute.values)
                    FilterChip(
                      label: Text(value.label),
                      selected:
                          (state.assignments[attribute.id] ?? const [])
                              .contains(value.id),
                      onSelected: (selected) => ref
                          .read(
                            productFormViewModelProvider(
                              productId,
                            ).notifier,
                          )
                          .setAssignmentValue(
                            attribute.id,
                            value.id,
                            selected,
                            isMulti: attribute.type == AttributeType.multiSelect,
                          ),
                    ),
                ],
              ),
              const Gap(AppSpacing.md),
            ],
          ],
        );
      },
    );
  }
}
