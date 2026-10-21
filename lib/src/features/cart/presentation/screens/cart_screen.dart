import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/utils/image_url.dart';
import 'package:bakery_mobile/src/features/cart/domain/models/cart_item.dart';
import 'package:bakery_mobile/src/features/cart/presentation/screens/checkout_screen.dart';
import 'package:bakery_mobile/src/shared/widgets/app_network_image_widget.dart';
import 'package:bakery_mobile/src/shared/utils/format_utils.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartViewModelProvider);
    final auth = ref.watch(authViewModelProvider);
    final membership = ref.watch(membershipViewModelProvider);

    if (auth.user != null &&
        !membership.isLoading &&
        membership.benefits == null &&
        membership.errorMessage == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(membershipViewModelProvider.notifier).load();
      });
    }

    final discountPercent =
        membership.benefits?.currentTier.discountPercent ?? 0;
    final membershipDiscount = auth.user == null
        ? 0.0
        : (cart.subtotal * (discountPercent / 100)).roundToDouble();
    final estimatedTotal = cart.subtotal - membershipDiscount;

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: cart.items.isEmpty
          ? const _EmptyCartView()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      0,
                    ),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _CartTile(item: cart.items[index]),
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Subtotal',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const Spacer(),
                                Text(
                                  formatVnd(cart.subtotal),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            if (auth.user != null && discountPercent > 0) ...[
                              const Gap(AppSpacing.sm),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${membership.benefits?.currentTier.label ?? 'Member'} saving',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ),
                                  Text(
                                    '-${formatVnd(membershipDiscount)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                children: [
                                  Text(
                                    'Estimated total',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const Spacer(),
                                  Text(
                                    formatVnd(estimatedTotal),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ] else if (auth.user == null) ...[
                              const Gap(AppSpacing.sm),
                              Text(
                                'Sign in to apply membership savings.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            const Gap(AppSpacing.md),
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const CheckoutScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.payments_outlined),
                              label: const Text('Proceed to checkout'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CartTile extends ConsumerWidget {
  const _CartTile({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartViewModelProvider.notifier);
    final imageUrl = resolveImageUrl(item.imageUrl);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppNetworkImageWidget(
              url: imageUrl,
              width: 84,
              height: 84,
              borderRadius: BorderRadius.circular(AppRadius.md),
              emptyIcon: Icons.cake_outlined,
            ),
            const Gap(AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.variantName != null &&
                      item.variantName!.trim().isNotEmpty) ...[
                    const Gap(AppSpacing.xs),
                    Text(
                      item.variantName!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const Gap(AppSpacing.sm),
                  Text(
                    formatVnd(item.price),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(AppSpacing.sm),
                  Row(
                    children: [
                      _QtyButton(
                        icon: Icons.remove,
                        onTap: () => cart.decrease(item),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      _QtyButton(
                        icon: Icons.add,
                        onTap: () => cart.increase(item),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => cart.remove(item),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Remove item',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16),
      ),
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 42,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Gap(AppSpacing.lg),
            Text(
              'Your cart is empty',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Gap(AppSpacing.sm),
            Text(
              'Pick your favorite cakes and desserts to start an order.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
