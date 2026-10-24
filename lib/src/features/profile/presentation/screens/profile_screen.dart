import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/shared/widgets/app_text_input_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/skeleton_order_card_widget.dart';
import 'package:bakery_mobile/src/features/addresses/presentation/screens/addresses_screen.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:bakery_mobile/src/features/blog/presentation/screens/blog_screen.dart';
import 'package:bakery_mobile/src/features/cart/domain/models/cart_item.dart';
import 'package:bakery_mobile/src/features/chatbot/presentation/screens/chatbot_screen.dart';
import 'package:bakery_mobile/src/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:bakery_mobile/src/features/orders/domain/models/order.dart';
import 'package:bakery_mobile/src/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:bakery_mobile/src/features/pages/presentation/screens/pages_screen.dart';
import 'package:bakery_mobile/src/features/profile/presentation/delete_account_keys.dart';
import 'package:bakery_mobile/src/features/profile/presentation/screens/delete_account_screen.dart';
import 'package:bakery_mobile/src/shared/widgets/order_status_pill_widget.dart';
import 'package:bakery_mobile/src/shared/utils/format_utils.dart';
import 'package:bakery_mobile/src/shared/widgets/initial_avatar_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

/// Trailing characters of the order number shown in its round badge.
const int _orderBadgeChars = 3;

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
        appBar: AppBar(title: const Text('Hồ sơ')),
        body: const Center(child: Text('Vui lòng đăng nhập để xem hồ sơ.')),
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
        title: const Text('Hồ sơ'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: auth.isSubmitting
                ? null
                : ref.read(authViewModelProvider.notifier).logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
          const Gap(AppSpacing.md),
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
          const Gap(AppSpacing.md),
          // "Sổ địa chỉ" — only reachable while signed in, same guard as the
          // order history section below (the body early-returns for guests).
          Card(
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.location_on_outlined,
                  title: 'Sổ địa chỉ',
                  subtitle: 'Quản lý địa chỉ giao hàng đã lưu',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddressesScreen(),
                      ),
                    );
                  },
                ),
                _ActionTile(
                  key: DeleteAccountKeys.entry,
                  icon: Icons.person_remove_outlined,
                  title: 'Xóa tài khoản',
                  subtitle: 'Xóa vĩnh viễn tài khoản và dữ liệu cá nhân',
                  onTap: () {
                    ref.read(authViewModelProvider.notifier).clearError();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DeleteAccountScreen(),
                      ),
                    );
                  },
                  hideDivider: true,
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.lg),
          _OrdersHeader(
            onRefresh: orders.isLoading
                ? null
                : ref.read(ordersViewModelProvider.notifier).loadMyOrders,
          ),
          if (orders.isLoadingOrders && orders.orders.isEmpty) ...[
            const SkeletonOrderCardWidget(),
            const Gap(AppSpacing.md),
            const SkeletonOrderCardWidget(),
            const Gap(AppSpacing.md),
          ],
          if (orders.errorMessage != null)
            Text(
              orders.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (!orders.isLoading && orders.orders.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    const Text('Chưa có đơn hàng'),
                    const Gap(AppSpacing.xs),
                    Text(
                      'Mua sắm ngay để xem lịch sử đơn hàng.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Gap(AppSpacing.sm),
                    OutlinedButton(
                      onPressed: () => ref
                          .read(ordersViewModelProvider.notifier)
                          .loadMyOrders(),
                      child: const Text('Làm mới'),
                    ),
                  ],
                ),
              ),
            ),
          ...orders.orders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _OrderCard(
                order: order,
                pointsEarned: membership.benefits?.pointsFor(order.total),
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
          if (orders.hasMoreOrders)
            Center(
              child: TextButton(
                onPressed: orders.isLoadingMoreOrders
                    ? null
                    : ref.read(ordersViewModelProvider.notifier).loadMoreOrders,
                child: Text(
                  orders.isLoadingMoreOrders
                      ? 'Đang tải…'
                      : 'Xem thêm đơn hàng',
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
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sửa hồ sơ',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Gap(AppSpacing.lg),
              AppTextInputWidget(
                controller: nameCtrl,
                labelText: 'Họ tên',
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              const Gap(AppSpacing.md),
              AppTextInputWidget(
                controller: phoneCtrl,
                labelText: 'Số điện thoại',
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              const Gap(AppSpacing.lg),
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
                child: const Text('Lưu hồ sơ'),
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
        ? 'Không thể đặt lại món nào từ đơn #${result.sourceOrderNumber}.'
        : unavailableCount > 0
        ? 'Đã chuẩn bị đặt lại đơn, có $unavailableCount món không khả dụng.'
        : 'Đã chuẩn bị đặt lại từ đơn #${result.sourceOrderNumber}.';

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
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            Text(
              'Món cần lưu ý',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Gap(AppSpacing.md),
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
        : 'Khách hàng';
    final displayLevel = (level?.trim().isNotEmpty ?? false)
        ? level!.trim()
        : 'SILVER';
    final tierLabel = (currentTierLabel?.trim().isNotEmpty ?? false)
        ? currentTierLabel!.trim()
        : displayLevel;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                InitialAvatarWidget(
                  name: displayName,
                  radius: 24,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer,
                ),
                const Gap(AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Gap(AppSpacing.xxs),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (phone?.trim().isNotEmpty ?? false) ...[
                        const Gap(AppSpacing.xxs),
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
                  tooltip: 'Sửa hồ sơ',
                ),
              ],
            ),
            const Gap(AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _ProfileStatChip(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Hạng',
                    value: tierLabel,
                  ),
                ),
                const Gap(AppSpacing.md),
                Expanded(
                  child: _ProfileStatChip(
                    icon: Icons.stars_outlined,
                    label: 'Điểm',
                    value: '$points',
                  ),
                ),
              ],
            ),
            if (discountPercent != null || eligibilityMessage != null) ...[
              const Gap(AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (discountPercent != null)
                      Text(
                        'Giảm giá thành viên ${discountPercent!.toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    if (eligibilityMessage != null &&
                        eligibilityMessage!.isNotEmpty) ...[
                      const Gap(AppSpacing.xs),
                      Text(
                        eligibilityMessage!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (nextTierLabel != null && pointsNeeded != null) ...[
                      const Gap(AppSpacing.xs),
                      Text(
                        'Cần thêm $pointsNeeded điểm để đạt hạng $nextTierLabel',
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const Gap(AppSpacing.sm),
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
            title: 'Thông báo',
            subtitle: '$unreadNotifications chưa đọc',
            onTap: onOpenNotifications,
          ),
          _ActionTile(
            icon: Icons.article_outlined,
            title: 'Blog',
            subtitle: 'Đọc tin tức và cập nhật',
            onTap: onOpenBlog,
          ),
          _ActionTile(
            icon: Icons.chat_bubble_outline,
            title: 'Trợ lý',
            subtitle: 'Nhận gợi ý sản phẩm',
            onTap: onOpenChatbot,
          ),
          _ActionTile(
            icon: Icons.menu_book_outlined,
            title: 'Chính sách & Trang',
            subtitle: 'Điều khoản, chính sách và giới thiệu',
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
    super.key,
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
          'Lịch sử đơn hàng',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Làm mới đơn hàng',
        ),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.pointsEarned,
    required this.isPreparingReorder,
    required this.onReorder,
    required this.onOpenDetail,
  });

  final Order order;

  /// Membership points this order earns; null while the membership rules
  /// are not loaded (nothing is shown rather than a guessed number).
  final int? pointsEarned;
  final bool isPreparingReorder;
  final VoidCallback onReorder;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final firstItemName = order.orderItems.isNotEmpty
        ? order.orderItems.first.name
        : 'Chưa có món';
    final extraItems = order.orderItems.length > 1
        ? ' +${order.orderItems.length - 1} món khác'
        : '';
    final createdAt = order.createdAt.toLocal();
    final dateText =
        '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    final canReorder = order.status.toUpperCase() == 'COMPLETED';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenDetail,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
          ),
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
                      order.orderNumber.length >= _orderBadgeChars
                          ? order.orderNumber.substring(
                              order.orderNumber.length - _orderBadgeChars,
                            )
                          : order.orderNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Gap(AppSpacing.md),
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
                            OrderStatusPillWidget(status: order.status),
                          ],
                        ),
                        const Gap(AppSpacing.xs),
                        Text(
                          '$firstItemName$extraItems',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Gap(AppSpacing.xxs),
                        Text(
                          dateText,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Gap(AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatVnd(order.total),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (pointsEarned != null) ...[
                        const Gap(AppSpacing.xxs),
                        Text(
                          '+${pointsEarned!} điểm',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              if (canReorder) ...[
                const Gap(AppSpacing.md),
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
                      isPreparingReorder
                          ? 'Đang chuẩn bị đặt lại...'
                          : 'Đặt lại đơn',
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
