// AdminShell — the shell every ADMIN lands in after login (mobile admin).
//
// Section switching strategy: the shell keeps `_currentSection` plus a
// `GlobalKey<NavigatorState>` for the nested body Navigator. Selecting a
// drawer entry swaps the key for a fresh one and rebuilds the nested
// `Navigator(onGenerateRoute:)`, so the new root route is always the selected
// section's screen (chosen over `pushAndRemoveUntil`: no route animation plays
// while the drawer is closing and there is no back stack to manage).
// Task 6 wired the dashboard branch to the real DashboardScreen; every other
// section still renders AdminPlaceholderScreen.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/admin/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:bakery_mobile/src/features/admin/shell/domain/admin_section.dart';
import 'package:bakery_mobile/src/features/admin/shell/presentation/screens/admin_placeholder_screen.dart';

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
                    SizedBox(width: 8),
                    Text('Đăng xuất'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: CircleAvatar(
                backgroundColor: AppTheme.primaryPink,
                foregroundColor: Colors.white,
                child: Text(
                  _initialOf(auth.user?.name),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
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
          // Dashboard (Tổng quan) is the real screen; the remaining sections
          // keep the placeholder until their phase lands.
          return MaterialPageRoute<void>(
            builder: (_) => _currentSection == AdminSection.dashboard
                ? const DashboardScreen()
                : AdminPlaceholderScreen(_currentSection.vietnameseTitle),
            settings: settings,
          );
        },
      ),
    );
  }
}

String _initialOf(String? name) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) return 'A';
  return trimmed.substring(0, 1).toUpperCase();
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
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bakery_dining_rounded,
                      color: AppTheme.primaryPink,
                    ),
                    const SizedBox(width: 8),
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
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.primaryPink,
                      foregroundColor: Colors.white,
                      child: Text(
                        _initialOf(displayName),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
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
