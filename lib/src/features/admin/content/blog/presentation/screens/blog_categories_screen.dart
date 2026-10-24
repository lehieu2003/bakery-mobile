import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/features/admin/content/blog/domain/models/blog_models.dart';

/// Shared list-crud screen for blog categories and tags (identical wire
/// shape: bare name/slug rows).
class BlogTaxoScreen extends ConsumerStatefulWidget {
  const BlogTaxoScreen({super.key, required this.isTags});

  final bool isTags;

  @override
  ConsumerState<BlogTaxoScreen> createState() => _BlogTaxoScreenState();
}

class _BlogTaxoScreenState extends ConsumerState<BlogTaxoScreen> {
  List<BlogCategory> _categories = [];
  List<BlogTag> _tags = [];
  var _isLoading = true;
  String? _error;

  String get _label => widget.isTags ? 'Blog tags' : 'Blog danh mục';

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final repo = ref.read(blogAdminRepositoryProvider);
    try {
      if (widget.isTags) {
        _tags = await repo.getTags();
      } else {
        _categories = await repo.getCategories();
      }
    } catch (error) {
      _error = '$error';
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _add() async {
    final name = await _promptName();
    if (name == null || name.trim().isEmpty) return;
    final repo = ref.read(blogAdminRepositoryProvider);
    if (widget.isTags) {
      await repo.createTag({'name': name.trim()});
    } else {
      await repo.createCategory({'name': name.trim()});
    }
    await _load();
  }

  Future<void> _remove(dynamic id) async {
    final repo = ref.read(blogAdminRepositoryProvider);
    if (widget.isTags) {
      await repo.deleteTag(id.toString());
    } else {
      await repo.deleteCategory(id.toString());
    }
    await _load();
  }

  Future<String?> _promptName() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm $_label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Tên'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.isTags ? _tags : _categories;
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  const Gap(8),
                  FilledButton(onPressed: _load, child: const Text('Thử lại')),
                ],
              ),
            )
          : rows.isEmpty
          ? Center(
              child: Text(
                'Chưa có $_label nào',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                itemBuilder: (context, index) {
                  final dynamic row = rows[index];
                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      title: Text(row.name),
                      subtitle: Text('/${row.slug}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _remove(row.id),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: Text('Thêm $_label'),
      ),
    );
  }
}
