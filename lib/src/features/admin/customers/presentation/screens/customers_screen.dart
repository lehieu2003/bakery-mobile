import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_durations.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/admin/customers/domain/models/admin_customer.dart';
import 'package:bakery_mobile/src/features/admin/customers/presentation/controllers/customers_admin_view_model.dart';
import 'package:bakery_mobile/src/features/admin/customers/presentation/screens/customer_detail_screen.dart';
import 'package:bakery_mobile/src/features/admin/customers/presentation/widgets/member_level_badge.dart';
import 'package:bakery_mobile/src/features/admin/shared/presentation/widgets/admin_paged_list.dart';
import 'package:bakery_mobile/src/shared/utils/format_utils.dart';
import 'package:bakery_mobile/src/shared/widgets/initial_avatar_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

/// Member-level filter chips: 'Tất cả' plus the 3 server tiers. Labels keep
/// the raw codes (SILVER/GOLD/PLATINUM) like the web admin.
final List<AdminFilterChip> _levelFilters = [
  const AdminFilterChip(label: 'Tất cả', value: allLevelsFilter),
  for (final level in const ['SILVER', 'GOLD', 'PLATINUM'])
    AdminFilterChip(label: level, value: level),
];

/// Admin customers list (section "Khách hàng"): search, tier filter and
/// infinite scroll. Tapping a card opens the customer detail.
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  /// Raw text of the search field. Kept here (not read back from the VM's
  /// trimmed, debounced `search`) so rebuilds never overwrite what the admin
  /// is still typing.
  String _searchText = '';
  Timer? _debounce;

  CustomersAdminViewModel get _vm =>
      ref.read(customersAdminViewModelProvider.notifier);

  @override
  void initState() {
    super.initState();
    _searchText = ref.read(customersAdminViewModelProvider).search;
    Future.microtask(_vm.load);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchText = value);
    _debounce?.cancel();
    _debounce = Timer(AppDurations.searchDebounce, () => _vm.setSearch(value));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersAdminViewModelProvider);

    // A failed refresh/load-more while customers are already on screen is not
    // rendered by AdminPagedList unless a next page exists (its footer) —
    // surface it as a snackbar instead.
    ref.listen<CustomersAdminState>(customersAdminViewModelProvider, (
      prev,
      next,
    ) {
      final error = next.error;
      if (error == null || error == prev?.error) return;
      if (next.items.isEmpty || next.hasMore) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    });

    return AdminPagedList<AdminCustomer>(
      items: state.items,
      isLoading: state.isLoading,
      error: state.error,
      onRetry: _vm.retry,
      isLoadingMore: state.isLoadingMore,
      hasMore: state.hasMore,
      onLoadMore: _vm.loadMore,
      onRefresh: _vm.load,
      itemBuilder: (context, customer) => _CustomerCard(customer: customer),
      searchHint: 'Tìm tên, email, số điện thoại',
      searchText: _searchText,
      onSearchChanged: _onSearchChanged,
      filters: _levelFilters,
      selectedFilter: state.levelFilter ?? allLevelsFilter,
      onFilterSelected: (value) => _vm.setFilter(value ?? allLevelsFilter),
      emptyText: 'Chưa có khách hàng',
    );
  }
}

/// One row of the admin customers list: avatar + name/email + tier badge,
/// points, and order count + lifetime spend. Tapping it opens the detail.
class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer});

  final AdminCustomer customer;

  void _openDetail(BuildContext context) {
    // Root navigator: the detail has its own AppBar and must cover the
    // AdminShell chrome (this screen lives in the shell's nested Navigator).
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => CustomerDetailScreen(customerId: customer.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: AppTheme.warmBrown,
    );
    final hasName = customer.name?.trim().isNotEmpty ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Initial from the display name, falling back to the email —
                  // every customer account has one.
                  InitialAvatarWidget(
                    name: hasName ? customer.name : customer.email,
                    radius: 20,
                    fallback: '?',
                  ),
                  const Gap(AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasName ? customer.name! : customer.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.inkBrown,
                          ),
                        ),
                        if (hasName)
                          Text(
                            customer.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: muted,
                          ),
                      ],
                    ),
                  ),
                  const Gap(AppSpacing.sm),
                  MemberLevelBadge(level: customer.memberLevel),
                ],
              ),
              const Gap(AppSpacing.sm),
              Text(
                '${customer.points} điểm',
                style: theme.textTheme.bodyMedium,
              ),
              const Gap(AppSpacing.xs),
              Text(
                '${customer.totalOrders} đơn hàng · ${formatVnd(customer.totalSpent)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
