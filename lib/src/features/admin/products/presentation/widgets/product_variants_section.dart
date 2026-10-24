import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/features/admin/products/presentation/controllers/product_form_view_model.dart';

/// Dynamic variant rows of the product form (name / SKU / price / stock),
/// added and removed inline — parity with the web form.
class ProductVariantsSection extends ConsumerWidget {
  const ProductVariantsSection({super.key, this.productId});

  final String? productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productFormViewModelProvider(productId));
    final vm = ref.read(productFormViewModelProvider(productId).notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < state.variants.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                        controller: TextEditingController(
                          text: state.variants[i].name,
                        )..selection = TextSelection.collapsed(
                          offset: state.variants[i].name.length,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Tên biến thể',
                        ),
                        onChanged: (v) => vm.updateVariant(i, name: v),
                      ),
                      const Gap(AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(
                                text: state.variants[i].sku,
                              )..selection = TextSelection.collapsed(
                                offset: state.variants[i].sku.length,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'SKU',
                              ),
                              onChanged: (v) => vm.updateVariant(i, sku: v),
                            ),
                          ),
                          const Gap(AppSpacing.sm),
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(
                                text: state.variants[i].priceText,
                              )..selection = TextSelection.collapsed(
                                offset: state.variants[i].priceText.length,
                              ),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Giá (₫)',
                              ),
                              onChanged: (v) =>
                                  vm.updateVariant(i, priceText: v),
                            ),
                          ),
                          const Gap(AppSpacing.sm),
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(
                                text: state.variants[i].stockText,
                              )..selection = TextSelection.collapsed(
                                offset: state.variants[i].stockText.length,
                              ),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Kho',
                              ),
                              onChanged: (v) => vm.updateVariant(i, stockText: v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => vm.removeVariant(i),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: vm.addVariant,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Thêm biến thể'),
          ),
        ),
      ],
    );
  }
}
