import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/utils/image_url.dart';
import 'package:bakery_mobile/src/features/cart/domain/models/cart_item.dart';
import 'package:bakery_mobile/src/features/cart/presentation/screens/checkout_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: cart.items.isEmpty
          ? const _EmptyCartView()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CartTile(item: cart.items[index]),
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
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
                                  '${cart.subtotal.toStringAsFixed(0)} VND',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
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
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl.isEmpty
                  ? Container(
                      width: 84,
                      height: 84,
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      alignment: Alignment.center,
                      child: const Icon(Icons.cake_outlined),
                    )
                  : Image.network(
                      imageUrl,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 84,
                        height: 84,
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHigh,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
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
                    const SizedBox(height: 4),
                    Text(
                      item.variantName!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${item.price.toStringAsFixed(0)} VND',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _QtyButton(
                        icon: Icons.remove,
                        onTap: () => cart.decrease(item),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
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
      borderRadius: BorderRadius.circular(999),
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
        padding: const EdgeInsets.symmetric(horizontal: 28),
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
            const SizedBox(height: 14),
            Text(
              'Your cart is empty',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
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
