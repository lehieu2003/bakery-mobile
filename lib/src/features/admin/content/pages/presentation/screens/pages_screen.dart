import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/features/admin/content/pages/domain/models/admin_page.dart';
import 'package:bakery_mobile/src/features/admin/content/pages/presentation/controllers/pages_admin_view_model.dart';
import 'package:bakery_mobile/src/features/admin/content/pages/presentation/widgets/page_edit_sheet.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';

/// Static pages admin: list, create/edit sheet, delete confirm.
class PagesScreen extends ConsumerStatefulWidget {
  const PagesScreen({super.key});

  @override
  ConsumerState<PagesScreen> createState() => _PagesScreenState();
}

class _PagesScreenState extends ConsumerState<PagesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(pagesAdminViewModelProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pagesAdminViewModelProvider);
    final vm = ref.read(pagesAdminViewModelProvider.notifier);

    return Scaffold(
      body: state.isLoading && state.pages.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.pages.isEmpty
          ? ErrorRetryWidget(message: state.error!, onRetry: vm.load)
          : state.pages.isEmpty
          ? Center(
              child: Text(
                'Chưa có trang tĩnh nào',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : RefreshIndicator(
              onRefresh: vm.load,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: state.pages.length,
                separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                itemBuilder: (context, index) => _PageCard(
                  page: state.pages[index],
                  onEdit: () =>
                      showPageEditSheet(context, page: state.pages[index]),
                  onDelete: () => _confirmDelete(state.pages[index]),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showPageEditSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm trang'),
      ),
    );
  }

  Future<void> _confirmDelete(AdminPage page) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa trang?'),
        content: Text('"${page.title}" sẽ biến mất khỏi website.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(pagesAdminViewModelProvider.notifier).remove(page.id);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa trang')));
    }
  }
}

class _PageCard extends StatelessWidget {
  const _PageCard({
    required this.page,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminPage page;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text(page.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('/${page.slug}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              page.isPublished ? 'Đã xuất bản' : 'Bản nháp',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: page.isPublished ? Colors.green.shade700 : Colors.grey,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}
