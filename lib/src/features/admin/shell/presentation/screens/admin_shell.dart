// AdminShell — the shell every ADMIN lands in after login (mobile admin).
//
// Section switching strategy: the shell keeps `_currentSection` plus a
// `GlobalKey<NavigatorState>` for the nested body Navigator. Selecting a
// drawer entry swaps the key for a fresh one and rebuilds the nested
// `Navigator(onGenerateRoute:)`, so the new root route is always the selected
// section's screen (chosen over `pushAndRemoveUntil`: no route animation plays
// while the drawer is closing and there is no back stack to manage).
// Real screens: dashboard (phase 1) and orders (phase 2); every other section
// still renders AdminPlaceholderScreen.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/admin/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:bakery_mobile/src/features/admin/orders/presentation/screens/orders_screen.dart';
import 'package:bakery_mobile/src/features/admin/shell/domain/admin_section.dart';
import 'package:bakery_mobile/src/features/admin/shell/presentation/screens/admin_placeholder_screen.dart';
import 'package:bakery_mobile/src/shared/widgets/initial_avatar_widget.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  AdminSection _currentSection = AdminSection.dashboard;
  GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  void _selectSection(AdminSection section) {
    Navigator.of(context).pop(); // close the drawer on the root navigator
    if (section == _currentSection) return;
    setState(() {
      _currentSection = section;
      _navigatorKey = GlobalKey<NavigatorState>();
    });
  }

  Future<void> _logout() {
    return ref.read(authViewModelProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentSection.vietnameseTitle),
        actions: [
          PopupMenuButton<String>(
            key: const Key('admin_shell_avatar'),
            tooltip: 'Tài khoản',
            onSelected: (value) {
              if (value == 'logout') _logout();
            },
            itemBuilder: (_) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    Gap(AppSpacing.sm),
                    Text('Đăng xuất'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: InitialAvatarWidget(name: auth.user?.name, fallback: 'A'),
            ),
          ),
        ],
      ),
      drawer: _AdminDrawer(
        currentSection: _currentSection,
        userName: auth.user?.name,
        userEmail: auth.user?.email,
        onSelect: _selectSection,
      ),
      body: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (settings) {
          // Sections without a real screen yet keep the placeholder until
          // their phase lands.
          return MaterialPageRoute<void>(
            builder: (_) => switch (_currentSection) {
              AdminSection.dashboard => const DashboardScreen(),
              AdminSection.orders => const OrdersScreen(),
              _ => AdminPlaceholderScreen(_currentSection.vietnameseTitle),
            },
            settings: settings,
          );
        },
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer({
    required this.currentSection,
    required this.userName,
    required this.userEmail,
    required this.onSelect,
  });

  final AdminSection currentSection;
  final String? userName;
  final String? userEmail;
  final ValueChanged<AdminSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final displayName = (userName?.trim().isNotEmpty ?? false)
        ? userName!.trim()
        : 'Quản trị viên';
    final displayEmail = (userEmail?.trim().isNotEmpty ?? false)
        ? userEmail!.trim()
        : '';

    return Drawer(
      child: SafeArea(
        // SingleChildScrollView (not a lazy ListView) so every group header and
        // entry is materialised regardless of viewport height.
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bakery_dining_rounded,
                      color: AppTheme.primaryPink,
                    ),
                    const Gap(AppSpacing.sm),
                    Text(
                      'Bakery Admin',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.inkBrown,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              for (final group in AdminSectionGroup.values) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xs,
                  ),
                  child: Text(
                    group.vietnameseTitle,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.warmBrown.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                for (final section in group.sections)
                  ListTile(
                    leading: Icon(
                      section.icon,
                      color: section == currentSection
                          ? AppTheme.primaryPink
                          : null,
                    ),
                    title: Text(section.vietnameseTitle),
                    selected: section == currentSection,
                    selectedColor: AppTheme.primaryPink,
                    onTap: () => onSelect(section),
                  ),
              ],
              const Divider(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Row(
                  children: [
                    InitialAvatarWidget(
                      name: displayName,
                      radius: 16,
                      fallback: 'A',
                    ),
                    const Gap(AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (displayEmail.isNotEmpty)
                            Text(
                              displayEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                        ],
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
