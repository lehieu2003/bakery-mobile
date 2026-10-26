import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/shared/widgets/app_text_input_widget.dart';
import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isRegister = false;
  bool _otpSent = false;
  bool _isReset = false;
  bool _hidePassword = true;
  bool _hideNewPassword = true;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _otpCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceAuth,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, _) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.x3l,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(AppRadius.sheet),
                      border: Border.all(color: AppTheme.outlineBeige),
                      boxShadow: const [
                        BoxShadow(
                          color: AppTheme.shadowAuthCard,
                          blurRadius: 32,
                          offset: Offset(0, 18),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sheet),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _BakeryHeader(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.xxl,
                              AppSpacing.xxl,
                              AppSpacing.xxl,
                              AppSpacing.xxl,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Gap(AppSpacing.sm),
                                Text(
                                  _subtitle(),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.textMuted,
                                        height: 1.35,
                                      ),
                                ),
                                const Gap(AppSpacing.xxl),
                                _buildForm(context, viewModel),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, AuthState viewModel) {
    // One autofill group so password managers fill email + password
    // together and offer to save them after a successful sign-in.
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextInputWidget(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email, AutofillHints.username],
            labelText: 'Email',
            prefixIcon: const Icon(Icons.mail_outline),
          ),
          const Gap(AppSpacing.md),
          if (_isRegister && _otpSent) ...[
            AppTextInputWidget(
              controller: _nameCtrl,
              autofillHints: const [AutofillHints.name],
              labelText: 'Họ tên (không bắt buộc)',
              prefixIcon: const Icon(Icons.person_outline),
            ),
            const Gap(AppSpacing.md),
            AppTextInputWidget(
              controller: _otpCtrl,
              autofillHints: const [AutofillHints.oneTimeCode],
              labelText: 'OTP',
              prefixIcon: const Icon(Icons.pin_outlined),
            ),
            const Gap(AppSpacing.md),
          ],
          if (_isReset && _otpSent) ...[
            AppTextInputWidget(
              controller: _otpCtrl,
              autofillHints: const [AutofillHints.oneTimeCode],
              labelText: 'OTP',
              prefixIcon: const Icon(Icons.pin_outlined),
            ),
            const Gap(AppSpacing.md),
            AppTextInputWidget(
              controller: _newPasswordCtrl,
              obscureText: _hideNewPassword,
              autofillHints: const [AutofillHints.newPassword],
              labelText: 'Mật khẩu mới',
              prefixIcon: const Icon(Icons.lock_reset_outlined),
              suffixIcon: IconButton(
                tooltip: _hideNewPassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                onPressed: () =>
                    setState(() => _hideNewPassword = !_hideNewPassword),
                icon: Icon(
                  _hideNewPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            const Gap(AppSpacing.md),
          ],
          if (!_isReset && (!_isRegister || _otpSent)) ...[
            AppTextInputWidget(
              controller: _passwordCtrl,
              obscureText: _hidePassword,
              autofillHints: [
                _isRegister
                    ? AutofillHints.newPassword
                    : AutofillHints.password,
              ],
              labelText: 'Mật khẩu',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _hidePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
                icon: Icon(
                  _hidePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            const Gap(AppSpacing.md),
          ],
          if (viewModel.errorMessage != null) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  viewModel.errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
            const Gap(AppSpacing.md),
          ],
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.buttonPrimaryAuth,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
            ),
            onPressed: viewModel.isSubmitting ? null : _submit,
            child: viewModel.isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(_primaryCta()),
          ),
          if (!_isReset && !_otpSent) ...[
            const Gap(AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Colors.brown.withValues(alpha: 0.2),
                    height: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(
                    'HOẶC',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: Colors.brown.withValues(alpha: 0.2),
                    height: 1,
                  ),
                ),
              ],
            ),
            const Gap(AppSpacing.md),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2C1810),
                minimumSize: const Size.fromHeight(50),
                side: BorderSide(color: Colors.brown.withValues(alpha: 0.25)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
              ),
              onPressed: viewModel.isSubmitting ? null : _loginWithGoogle,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  _GoogleLogo(size: 18),
                  Gap(AppSpacing.xs),
                  Flexible(
                    child: Text(
                      'Đăng nhập bằng Google',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Gap(AppSpacing.md),
          if (!_isReset && !_isRegister)
            TextButton(
              onPressed: () {
                setState(() {
                  _isReset = true;
                  _otpSent = false;
                  _otpCtrl.clear();
                  _newPasswordCtrl.clear();
                });
              },
              child: const Text('Quên mật khẩu?'),
            ),
          TextButton(
            onPressed: () {
              setState(() {
                _isRegister = !_isRegister;
                _isReset = false;
                _otpSent = false;
                _otpCtrl.clear();
              });
            },
            child: Text(
              _isRegister
                  ? 'Đã có tài khoản? Đăng nhập'
                  : 'Chưa có tài khoản? Đăng ký',
            ),
          ),
          if (_isReset)
            TextButton(
              onPressed: () {
                setState(() {
                  _isReset = false;
                  _otpSent = false;
                  _otpCtrl.clear();
                  _newPasswordCtrl.clear();
                });
              },
              child: const Text('Quay lại đăng nhập'),
            ),
        ],
      ),
    );
  }

  // String _title() {
  //   if (_isReset) return 'Reset password';
  //   return _isRegister ? 'Register' : 'Sign in';
  // }

  String _subtitle() {
    if (_isReset) return 'Nhận mật khẩu mới và quay lại giỏ hàng của bạn.';
    if (_isRegister && !_otpSent) {
      return 'Tạo tài khoản tiệm bánh bằng email và mã OTP.';
    }
    if (_isRegister) return 'Nhập mã OTP đã gửi để hoàn tất hồ sơ của bạn.';
    return 'Chào mừng bạn quay lại với những bánh tươi mỗi ngày.';
  }

  String _primaryCta() {
    if (_isReset && !_otpSent) return 'Gửi mã OTP khôi phục';
    if (_isReset && _otpSent) return 'Xác nhận mật khẩu mới';
    if (_isRegister && !_otpSent) return 'Gửi mã OTP đăng ký';
    if (_isRegister && _otpSent) return 'Tạo tài khoản';
    return 'Đăng nhập';
  }

  Future<void> _submit() async {
    final viewModel = ref.read(authViewModelProvider.notifier);

    if (_emailCtrl.text.trim().isEmpty) return;

    bool ok = false;

    if (_isReset) {
      if (!_otpSent) {
        ok = await viewModel.sendResetPasswordOtp(
          email: _emailCtrl.text.trim(),
        );
        if (ok && mounted) {
          setState(() => _otpSent = true);
          _showSnack(context, 'Đã gửi mã OTP đến email của bạn.');
        }
      } else {
        ok = await viewModel.verifyResetPassword(
          email: _emailCtrl.text.trim(),
          otp: _otpCtrl.text.trim(),
          newPassword: _newPasswordCtrl.text,
        );
        if (ok && mounted) {
          _showSnack(context, 'Đã đặt lại mật khẩu. Vui lòng đăng nhập.');
          setState(() {
            _isReset = false;
            _otpSent = false;
          });
        }
      }
      return;
    }

    if (_isRegister) {
      if (!_otpSent) {
        ok = await viewModel.sendRegisterOtp(email: _emailCtrl.text.trim());
        if (ok && mounted) {
          setState(() => _otpSent = true);
          _showSnack(context, 'Đã gửi mã OTP đến email của bạn.');
        }
      } else {
        ok = await viewModel.verifyRegister(
          email: _emailCtrl.text.trim(),
          otp: _otpCtrl.text.trim(),
          password: _passwordCtrl.text,
          name: _nameCtrl.text.trim(),
        );
        if (ok) TextInput.finishAutofillContext();
        if (ok && mounted) {
          _showSnack(context, 'Đã đăng nhập với vai trò CUSTOMER.');
        }
      }
      return;
    }

    ok = await viewModel.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    // Prompts the password manager to save the credentials just used.
    if (ok) TextInput.finishAutofillContext();
  }

  Future<void> _loginWithGoogle() async {
    final viewModel = ref.read(authViewModelProvider.notifier);
    final ok = await viewModel.loginWithGoogle();
    if (ok) TextInput.finishAutofillContext();
    if (ok && mounted) {
      _showSnack(context, 'Đăng nhập Google thành công.');
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _BakeryHeader extends StatelessWidget {
  const _BakeryHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 178,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 2.2, sigmaY: 2.2),
            child: Image.asset(
              'assets/images/auth_bakery_header.png',
              fit: BoxFit.cover,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.authHeroFadeTop,
                  AppTheme.authHeroFadeMiddle,
                  AppTheme.authHeroFadeBottom,
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceAuthPill,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppTheme.outlineBeige),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(
                    'PHƯƠNG LOAN BAKERY',
                    style: TextStyle(
                      color: AppTheme.textBrandPill,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: const _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final redPaint = Paint()..color = const Color(0xFFEA4335);

    // Blue horizontal bar
    final bluePath = Path()
      ..moveTo(w * 0.95, h * 0.5)
      ..lineTo(w * 0.5, h * 0.5)
      ..lineTo(w * 0.5, h * 0.35)
      ..lineTo(w * 0.93, h * 0.35)
      ..arcToPoint(
        Offset(w * 0.88, h * 0.72),
        radius: Radius.circular(w * 0.45),
      )
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Green bottom arc
    final greenPath = Path()
      ..moveTo(w * 0.88, h * 0.72)
      ..arcToPoint(
        Offset(w * 0.28, h * 0.82),
        radius: Radius.circular(w * 0.45),
      )
      ..lineTo(w * 0.38, h * 0.64)
      ..arcToPoint(
        Offset(w * 0.76, h * 0.60),
        radius: Radius.circular(w * 0.28),
      )
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // Yellow left arc
    final yellowPath = Path()
      ..moveTo(w * 0.28, h * 0.82)
      ..arcToPoint(
        Offset(w * 0.28, h * 0.18),
        radius: Radius.circular(w * 0.45),
      )
      ..lineTo(w * 0.38, h * 0.36)
      ..arcToPoint(
        Offset(w * 0.38, h * 0.64),
        radius: Radius.circular(w * 0.28),
      )
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Red top arc
    final redPath = Path()
      ..moveTo(w * 0.28, h * 0.18)
      ..arcToPoint(
        Offset(w * 0.78, h * 0.22),
        radius: Radius.circular(w * 0.45),
      )
      ..lineTo(w * 0.65, h * 0.38)
      ..arcToPoint(
        Offset(w * 0.38, h * 0.36),
        radius: Radius.circular(w * 0.28),
      )
      ..close();
    canvas.drawPath(redPath, redPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
