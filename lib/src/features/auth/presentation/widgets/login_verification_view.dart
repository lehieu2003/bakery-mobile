import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/shared/widgets/app_text_input_widget.dart';

/// Second step of an admin sign-in on a phone that is not the trusted one:
/// the 6-digit code bakery-web emailed. On success this phone becomes the
/// trusted one and the previous phone is signed out.
class LoginVerificationView extends ConsumerStatefulWidget {
  const LoginVerificationView({super.key});

  @override
  ConsumerState<LoginVerificationView> createState() =>
      _LoginVerificationViewState();
}

class _LoginVerificationViewState extends ConsumerState<LoginVerificationView> {
  final _codeCtrl = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (code.length != 6) {
      setState(() => _localError = 'Nhập đủ 6 số trong email');
      return;
    }
    setState(() => _localError = null);
    await ref.read(authViewModelProvider.notifier).verifyLogin(code);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    final pending = auth.pendingVerification;
    final error = _localError ?? auth.errorMessage;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.peachTint,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: AppTheme.primaryPink,
                ),
                const Gap(AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xác minh điện thoại mới',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Gap(AppSpacing.xs),
                      Text(
                        'Tài khoản quản trị chỉ dùng được trên một điện thoại. '
                        'Nhập mã 6 số vừa gửi tới ${pending?.maskedEmail ?? 'email quản trị'} '
                        'để dùng máy này; máy cũ sẽ bị đăng xuất.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Gap(AppSpacing.lg),
        AppTextInputWidget(
          controller: _codeCtrl,
          labelText: 'Mã xác minh',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofocus: true,
          autofillHints: const [AutofillHints.oneTimeCode],
          prefixIcon: const Icon(Icons.pin_outlined),
          onSubmitted: (_) => _verify(),
        ),
        if (error != null) ...[
          const Gap(AppSpacing.md),
          Text(error, style: TextStyle(color: theme.colorScheme.error)),
        ],
        const Gap(AppSpacing.lg),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.buttonPrimaryAuth,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
          ),
          onPressed: auth.isSubmitting ? null : _verify,
          child: const Text('Xác minh'),
        ),
        const Gap(AppSpacing.sm),
        TextButton(
          onPressed: auth.isSubmitting
              ? null
              : ref.read(authViewModelProvider.notifier).cancelVerification,
          child: const Text('Quay lại đăng nhập'),
        ),
      ],
    );
  }
}
