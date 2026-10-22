import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/features/profile/presentation/delete_account_keys.dart';
import 'package:bakery_mobile/src/shared/widgets/app_text_input_widget.dart';
import 'package:bakery_mobile/src/shared/widgets/section_card_widget.dart';

const _erased = [
  'Họ tên, email, số điện thoại',
  'Sổ địa chỉ giao hàng',
  'Giỏ hàng và danh sách yêu thích',
  'Điểm thành viên và hạng thành viên',
  'Mọi phiên đăng nhập trên web và ứng dụng',
];

/// Account deletion (Google Play requirement). Same rules as the web page
/// /xoa-tai-khoan: password-confirmed, blocked while orders are open.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _password = TextEditingController();
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _password.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final deleted = await ref
        .read(authViewModelProvider.notifier)
        .deleteAccount(password: _password.text);
    if (!deleted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Tài khoản của bạn đã được xóa.')),
    );
    // Signed out now: AppGate shows the auth screen under this route.
    navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    final scheme = Theme.of(context).colorScheme;
    final canSubmit =
        _password.text.isNotEmpty && _confirmed && !auth.isSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('Xóa tài khoản')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const Text(
            'Việc xóa tài khoản không thể hoàn tác. Nếu bạn còn đơn hàng đang '
            'xử lý, vui lòng chờ đơn hoàn tất hoặc hủy đơn trước.',
          ),
          const Gap(AppSpacing.md),
          SectionCardWidget(
            title: 'Dữ liệu bị xóa',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.xs,
              children: [for (final item in _erased) Text('• $item')],
            ),
          ),
          const SectionCardWidget(
            title: 'Dữ liệu được giữ lại',
            child: Text(
              'Lịch sử đơn hàng được lưu ẩn danh tối thiểu 5 năm cho mục đích '
              'kế toán và giải quyết tranh chấp.',
            ),
          ),
          const Gap(AppSpacing.md),
          AppTextInputWidget(
            key: DeleteAccountKeys.password,
            controller: _password,
            obscureText: true,
            labelText: 'Nhập mật khẩu để xác nhận',
          ),
          CheckboxListTile(
            key: DeleteAccountKeys.confirm,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _confirmed,
            onChanged: (value) => setState(() => _confirmed = value ?? false),
            title: const Text(
              'Tôi hiểu tài khoản, điểm thành viên và dữ liệu cá nhân sẽ bị '
              'xóa vĩnh viễn.',
            ),
          ),
          if (auth.errorMessage != null)
            Padding(
              key: DeleteAccountKeys.error,
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                auth.errorMessage!,
                style: TextStyle(color: scheme.error),
              ),
            ),
          FilledButton(
            key: DeleteAccountKeys.submit,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: canSubmit ? _submit : null,
            child: Text(
              auth.isSubmitting ? 'Đang xóa…' : 'Xóa tài khoản vĩnh viễn',
            ),
          ),
        ],
      ),
    );
  }
}
