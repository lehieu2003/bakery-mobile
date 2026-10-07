import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/widgets/app_text_input.dart';
import 'package:bakery_mobile/src/core/widgets/skeleton_widgets.dart';
import 'package:bakery_mobile/src/features/addresses/presentation/screens/addresses_screen.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:bakery_mobile/src/features/blog/presentation/screens/blog_screen.dart';
import 'package:bakery_mobile/src/features/cart/domain/models/cart_item.dart';
import 'package:bakery_mobile/src/features/chatbot/presentation/screens/chatbot_screen.dart';
import 'package:bakery_mobile/src/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:bakery_mobile/src/features/orders/domain/models/order.dart';
import 'package:bakery_mobile/src/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:bakery_mobile/src/features/pages/presentation/screens/pages_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _requestedInitialOrders = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    final membership = ref.watch(membershipViewModelProvider);
    final orders = ref.watch(ordersViewModelProvider);
    final notifications = ref.watch(notificationsViewModelProvider);

    final user = auth.user;
    if (user == null) {
      _requestedInitialOrders = false;
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Please sign in to see your profile.')),
      );
    }

    if (!_requestedInitialOrders &&
        !orders.isLoading &&
        orders.orders.isEmpty) {
      _requestedInitialOrders = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(ordersViewModelProvider.notifier).loadMyOrders();
        ref.read(membershipViewModelProvider.notifier).load();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: auth.isSubmitting
                ? null
                : ref.read(authViewModelProvider.notifier).logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeaderCard(
            name: user.name,
            email: user.email,
            phone: user.phone,
            level: user.memberLevel,
            points: user.points ?? 0,
            currentTierLabel: membership.benefits?.currentTier.label,
            discountPercent: membership.benefits?.currentTier.discountPercent,
            eligibilityMessage: membership.benefits?.eligibilityMessage,
            nextTierLabel: membership.benefits?.nextTier?.label,
            pointsNeeded: membership.benefits?.nextTier?.pointsNeeded,
            isSaving: auth.isSubmitting,
            onEdit: () => _openEditProfile(user),
          ),
          const SizedBox(height: 12),
          _QuickActionsCard(
            unreadNotifications: notifications.unreadCount,
            onOpenNotifications: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
            onOpenBlog: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const BlogScreen()));
            },
            onOpenChatbot: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ChatbotScreen()));
            },
            onOpenPages: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PagesScreen()));
            },
          ),
          const SizedBox(height: 12),
          // "Sổ địa chỉ" — only reachable while signed in, same guard as the
          // order history section below (the body early-returns for guests).
          Card(
            child: _ActionTile(
              icon: Icons.location_on_outlined,
              title: 'Sổ địa chỉ',
              subtitle: 'Quản lý địa chỉ giao hàng đã lưu',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddressesScreen()),
                );
              },
              hideDivider: true,
            ),
          ),
          const SizedBox(height: 16),
          _OrdersHeader(
            onRefresh: orders.isLoading
                ? null
                : ref.read(ordersViewModelProvider.notifier).loadMyOrders,
          ),
          if (orders.isLoadingOrders && orders.orders.isEmpty) ...[
            const SkeletonOrderCard(),
            const SizedBox(height: 10),
            const SkeletonOrderCard(),
            const SizedBox(height: 10),
          ],
          if (orders.errorMessage != null)
            Text(
              orders.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (!orders.isLoading && orders.orders.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text('No orders yet'),
                    const SizedBox(height: 4),
                    Text(
                      'Start shopping to see your order history.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => ref
                          .read(ordersViewModelProvider.notifier)
                          .loadMyOrders(),
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            ),
          ...orders.orders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OrderCard(
                order: order,
                isPreparingReorder: orders.preparingReorderOrderId == order.id,
                onReorder: () => _prepareReorder(order),
                onOpenDetail: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          OrderDetailScreen(orderNumber: order.orderNumber),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditProfile(User user) async {
    final nameCtrl = TextEditingController(text: user.name ?? '');
    final phoneCtrl = TextEditingController(text: user.phone ?? '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit profile',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              AppTextInput(
                controller: nameCtrl,
                labelText: 'Name',
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              const SizedBox(height: 12),
              AppTextInput(
                controller: phoneCtrl,
                labelText: 'Phone',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final ok = await ref
                      .read(authViewModelProvider.notifier)
                      .updateProfile(
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                      );
                  if (!sheetContext.mounted) return;
                  if (ok) Navigator.of(sheetContext).pop();
                },
                child: const Text('Save profile'),
              ),
            ],
          ),
        );
      },
    );

    nameCtrl.dispose();
    phoneCtrl.dispose();
  }

  Future<void> _prepareReorder(Order order) async {
    final result = await ref
        .read(ordersViewModelProvider.notifier)
        .prepareReorder(order.id);
    if (!mounted || result == null) return;

    final cartItems = result.items
        .map(
          (item) => CartItem(
            productId: item.productId,
            variantId: item.variantId,
            variantName: item.variantName,
            name: item.variantName == null || item.variantName!.isEmpty
                ? item.name
                : '${item.name} (${item.variantName})',
            price: item.price,
            quantity: item.quantity,
            imageUrl: item.image,
          ),
        )
        .toList();

    ref.read(cartViewModelProvider.notifier).replaceItems(cartItems);

    final unavailableCount = result.unavailableItems.length;
    final message = cartItems.isEmpty
        ? 'No items from #${result.sourceOrderNumber} could be reordered.'
        : unavailableCount > 0
        ? 'Reorder prepared with $unavailableCount unavailable item(s).'
        : 'Reorder prepared from #${result.sourceOrderNumber}.';

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    if (unavailableCount > 0) {
      await _showUnavailableReorderItems(result.unavailableItems);
    }
  }

  Future<void> _showUnavailableReorderItems(
    List<ReorderUnavailableItem> items,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          children: [
            Text(
              'Items needing attention',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.name),
                subtitle: Text(item.guidance),
                trailing: Text(
                  '${item.availableQuantity}/${item.requestedQuantity}',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.email,
    required this.points,
    required this.isSaving,
    required this.onEdit,
    this.name,
    this.phone,
    this.level,
    this.currentTierLabel,
    this.discountPercent,
    this.eligibilityMessage,
    this.nextTierLabel,
    this.pointsNeeded,
  });

  final String? name;
  final String email;
  final String? phone;
  final String? level;
  final int points;
  final String? currentTierLabel;
  final double? discountPercent;
  final String? eligibilityMessage;
  final String? nextTierLabel;
  final int? pointsNeeded;
  final bool isSaving;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final displayName = (name?.trim().isNotEmpty ?? false)
        ? name!.trim()
        : 'Customer';
    final displayLevel = (level?.trim().isNotEmpty ?? false)
        ? level!.trim()
        : 'SILVER';
    final tierLabel = (currentTierLabel?.trim().isNotEmpty ?? false)
        ? currentTierLabel!.trim()
        : displayLevel;
    final initial = displayName.substring(0, 1).toUpperCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (phone?.trim().isNotEmpty ?? false) ...[
                        const SizedBox(height: 2),
                        Text(
                          phone!.trim(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: isSaving ? null : onEdit,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.edit_outlined),
                  tooltip: 'Edit profile',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ProfileStatChip(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Level',
                    value: tierLabel,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ProfileStatChip(
                    icon: Icons.stars_outlined,
                    label: 'Points',
                    value: '$points',
                  ),
                ),
              ],
            ),
            if (discountPercent != null || eligibilityMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (discountPercent != null)
                      Text(
                        '${discountPercent!.toStringAsFixed(0)}% membership discount',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    if (eligibilityMessage != null &&
                        eligibilityMessage!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        eligibilityMessage!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (nextTierLabel != null && pointsNeeded != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$pointsNeeded points to $nextTierLabel',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileStatChip extends StatelessWidget {
  const _ProfileStatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.unreadNotifications,
    required this.onOpenNotifications,
    required this.onOpenBlog,
    required this.onOpenChatbot,
    required this.onOpenPages,
  });

  final int unreadNotifications;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenBlog;
  final VoidCallback onOpenChatbot;
  final VoidCallback onOpenPages;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: '$unreadNotifications unread',
            onTap: onOpenNotifications,
          ),
          _ActionTile(
            icon: Icons.article_outlined,
            title: 'Blog',
            subtitle: 'Read news and updates',
            onTap: onOpenBlog,
          ),
          _ActionTile(
            icon: Icons.chat_bubble_outline,
            title: 'Chatbot',
            subtitle: 'Get product suggestions',
            onTap: onOpenChatbot,
          ),
          _ActionTile(
            icon: Icons.menu_book_outlined,
            title: 'Policy & Pages',
            subtitle: 'Terms, policy and about',
            onTap: onOpenPages,
            hideDivider: true,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.hideDivider = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool hideDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        if (!hideDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({required this.onRefresh});

  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Order History',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh orders',
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.isPreparingReorder,
    required this.onReorder,
    required this.onOpenDetail,
  });

  final Order order;
  final bool isPreparingReorder;
  final VoidCallback onReorder;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final firstItemName = order.orderItems.isNotEmpty
        ? order.orderItems.first.name
        : 'No items';
    final extraItems = order.orderItems.length > 1
        ? ' +${order.orderItems.length - 1} more'
        : '';
    final pointsEarned = (order.total * 0.2).floor();
    final createdAt = order.createdAt.toLocal();
    final dateText =
        '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    final canReorder = order.status.toUpperCase() == 'COMPLETED';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenDetail,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      order.orderNumber.length >= 3
                          ? order.orderNumber.substring(
                              order.orderNumber.length - 3,
                            )
                          : order.orderNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '#${order.orderNumber}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            _OrderStatusBadge(status: order.status.toString()),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$firstItemName$extraItems',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateText,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${order.total.toStringAsFixed(0)} VND',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '+$pointsEarned pts',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (canReorder) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isPreparingReorder ? null : onReorder,
                    icon: isPreparingReorder
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.replay_outlined),
                    label: Text(
                      isPreparingReorder ? 'Preparing reorder...' : 'Reorder',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderStatusBadge extends StatelessWidget {
  const _OrderStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final colorScheme = Theme.of(context).colorScheme;
    Color bg = colorScheme.secondaryContainer;
    Color fg = colorScheme.onSecondaryContainer;

    if (normalized.contains('CANCEL')) {
      bg = colorScheme.errorContainer;
      fg = colorScheme.onErrorContainer;
    } else if (normalized.contains('PAID') || normalized.contains('SUCCESS')) {
      bg = Colors.green.withValues(alpha: 0.14);
      fg = Colors.green.shade800;
    } else if (normalized.contains('PENDING')) {
      bg = Colors.orange.withValues(alpha: 0.16);
      fg = Colors.orange.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalized,
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }
}
