import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/features/admin/content/blog/presentation/controllers/blog_posts_admin_view_model.dart';

/// Compose a blog post (DRAFT by default; publishing via list toggle).
Future<void> showBlogPostCreateSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _BlogPostCreateSheet(),
  );
}

class _BlogPostCreateSheet extends ConsumerStatefulWidget {
  const _BlogPostCreateSheet();

  @override
  ConsumerState<_BlogPostCreateSheet> createState() =>
      _BlogPostCreateSheetState();
}

class _BlogPostCreateSheetState extends ConsumerState<_BlogPostCreateSheet> {
  final _title = TextEditingController();
  final _excerpt = TextEditingController();
  final _content = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _excerpt.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = await ref
        .read(blogPostsAdminViewModelProvider.notifier)
        .create(
          title: _title.text,
          content: _content.text,
          excerpt: _excerpt.text,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo bài viết (bản nháp)')),
      );
    } else {
      setState(() => _error = ref.read(blogPostsAdminViewModelProvider).error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(blogPostsAdminViewModelProvider).isSaving;
    return Padding(
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
          Text('Thêm bài viết', style: Theme.of(context).textTheme.titleLarge),
          const Gap(16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Tiêu đề'),
          ),
          const Gap(12),
          TextField(
            controller: _excerpt,
            decoration: const InputDecoration(labelText: 'Mô tả ngắn'),
            maxLines: 2,
          ),
          const Gap(12),
          TextField(
            controller: _content,
            decoration: const InputDecoration(
              labelText: 'Nội dung',
              alignLabelWithHint: true,
            ),
            maxLines: 6,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const Gap(16),
          FilledButton(
            onPressed: isSaving ? null : _save,
            child: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Lưu bản nháp'),
          ),
        ],
      ),
    );
  }
}
