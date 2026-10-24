import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/features/admin/content/pages/domain/models/admin_page.dart';
import 'package:bakery_mobile/src/features/admin/content/pages/presentation/controllers/pages_admin_view_model.dart';

/// Create/edit static page. Content edits are plain text (the web console
/// keeps the rich editor); newlines are stored verbatim.
Future<void> showPageEditSheet(BuildContext context, {AdminPage? page}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _PageEditSheet(page: page),
  );
}

class _PageEditSheet extends ConsumerStatefulWidget {
  const _PageEditSheet({this.page});

  final AdminPage? page;

  @override
  ConsumerState<_PageEditSheet> createState() => _PageEditSheetState();
}

class _PageEditSheetState extends ConsumerState<_PageEditSheet> {
  late final _title = TextEditingController(text: widget.page?.title ?? '');
  late final _slug = TextEditingController(text: widget.page?.slug ?? '');
  late final _content = TextEditingController(
    text: widget.page?.content ?? '',
  );
  late bool _isPublished = widget.page?.isPublished ?? false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _slug.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = await ref
        .read(pagesAdminViewModelProvider.notifier)
        .save(
          id: widget.page?.id,
          title: _title.text,
          slug: _slug.text,
          content: _content.text,
          isPublished: _isPublished,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _error = ref.read(pagesAdminViewModelProvider).error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(pagesAdminViewModelProvider).isSaving;
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
          Text(
            widget.page == null ? 'Thêm trang tĩnh' : 'Sửa trang tĩnh',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Gap(16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Tiêu đề'),
          ),
          const Gap(12),
          TextField(
            controller: _slug,
            decoration: const InputDecoration(
              labelText: 'Slug',
              hintText: 'để trống tự sinh',
            ),
          ),
          const Gap(12),
          TextField(
            controller: _content,
            decoration: const InputDecoration(
              labelText: 'Nội dung',
              alignLabelWithHint: true,
            ),
            maxLines: 8,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Xuất bản'),
            value: _isPublished,
            onChanged: (v) => setState(() => _isPublished = v),
          ),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const Gap(8),
          FilledButton(
            onPressed: isSaving ? null : _save,
            child: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
