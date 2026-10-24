import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/features/admin/content/notifications/presentation/controllers/notifications_admin_view_model.dart';

/// Compose a notification (DRAFT by default — publishing happens from the
/// web console where scheduling is available).
Future<void> showNotificationCreateSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _NotificationCreateSheet(),
  );
}

class _NotificationCreateSheet extends ConsumerStatefulWidget {
  const _NotificationCreateSheet();

  @override
  ConsumerState<_NotificationCreateSheet> createState() =>
      _NotificationCreateSheetState();
}

class _NotificationCreateSheetState
    extends ConsumerState<_NotificationCreateSheet> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _linkUrl = TextEditingController();
  String _status = 'DRAFT';
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _linkUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = await ref
        .read(notificationsAdminViewModelProvider.notifier)
        .create(
          title: _title.text,
          content: _content.text,
          linkUrl: _linkUrl.text,
          status: _status,
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã tạo thông báo')));
    } else {
      setState(
        () => _error = ref.read(notificationsAdminViewModelProvider).error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(notificationsAdminViewModelProvider).isSaving;
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
          Text('Soạn thông báo', style: Theme.of(context).textTheme.titleLarge),
          const Gap(16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Tiêu đề'),
          ),
          const Gap(12),
          TextField(
            controller: _content,
            decoration: const InputDecoration(labelText: 'Nội dung'),
            maxLines: 4,
          ),
          const Gap(12),
          TextField(
            controller: _linkUrl,
            decoration: const InputDecoration(
              labelText: 'Liên kết (không bắt buộc)',
            ),
          ),
          const Gap(12),
          DropdownButtonFormField<String>(
            value: _status,
            items: const [
              DropdownMenuItem(value: 'DRAFT', child: Text('Bản nháp')),
              DropdownMenuItem(value: 'PUBLISHED', child: Text('Đăng ngay')),
            ],
            onChanged: (v) => setState(() => _status = v ?? 'DRAFT'),
            decoration: const InputDecoration(labelText: 'Trạng thái'),
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
                : const Text('Tạo'),
          ),
        ],
      ),
    );
  }
}
