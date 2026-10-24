import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/features/admin/content/menu/domain/models/menu_models.dart';
import 'package:bakery_mobile/src/features/admin/content/menu/presentation/controllers/menu_admin_view_model.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';

/// Header menu items admin — the endpoint starts empty, so the empty state
/// carries the add CTA.
class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(menuAdminViewModelProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(menuAdminViewModelProvider);
    final vm = ref.read(menuAdminViewModelProvider.notifier);

    return Scaffold(
      body: state.isLoading && state.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.items.isEmpty
          ? ErrorRetryWidget(message: state.error!, onRetry: vm.load)
          : state.items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Chưa có mục menu nào',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const Gap(12),
                  FilledButton.icon(
                    onPressed: () => _showEditSheet(),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm mục đầu tiên'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: vm.load,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: state.items.length,
                separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                itemBuilder: (context, index) => _MenuCard(
                  item: state.items[index],
                  onEdit: () => _showEditSheet(item: state.items[index]),
                  onDelete: () => _confirmDelete(state.items[index]),
                ),
              ),
            ),
      floatingActionButton: state.items.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showEditSheet(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm mục'),
            ),
    );
  }

  Future<void> _showEditSheet({MenuModelsMenuItemRef? item}) async {
    final title = TextEditingController(text: item?.title ?? '');
    final url = TextEditingController(text: item?.url ?? '');
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              item == null ? 'Thêm mục menu' : 'Sửa mục menu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Gap(16),
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Tiêu đề'),
            ),
            const Gap(12),
            TextField(
              controller: url,
              decoration: const InputDecoration(labelText: 'Liên kết'),
            ),
            const Gap(20),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Xong'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(menuAdminViewModelProvider.notifier)
        .save(id: item?.id, title: title.text, url: url.text);
  }

  Future<void> _confirmDelete(MenuModelsMenuItemRef item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá mục menu?'),
        content: Text('"${item.title}" sẽ gỡ khỏi header website.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(menuAdminViewModelProvider.notifier).remove(item.id);
  }
}

/// Local alias so the sheet helper signature stays readable.
typedef MenuModelsMenuItemRef = AdminMenuItem;

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.item, required this.onEdit, required this.onDelete});

  final AdminMenuItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(item.url ?? '/'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
        onTap: onEdit,
      ),
    );
  }
}
