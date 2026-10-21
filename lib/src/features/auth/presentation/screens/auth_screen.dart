import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/shared/widgets/app_text_input_widget.dart';
import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';

/// Page background behind the auth card.
const Color _authBackground = Color(0xFFF8F1E8);

/// Soft caramel shadow under the auth card.
const Color _cardShadow = Color(0x1A9F7A5A);

/// Caramel fill of the primary auth button.
const Color _primaryButton = Color(0xFFB87B58);

/// Top stop of the header image fade.
const Color _heroFadeTop = Color(0x24FFFFFF);

/// Middle stop of the header image fade.
const Color _heroFadeMiddle = Color(0x66FFF8F0);

/// Bottom stop of the header image fade.
const Color _heroFadeBottom = Color(0xEEFFFFFF);

/// Text of the "BAKERY SHOP" pill.
const Color _brandPillText = Color(0xFF7A513A);

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
      backgroundColor: _authBackground,
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.sheet),
                      border: Border.all(color: AppTheme.outlineBeige),
                      boxShadow: const [
                        BoxShadow(
                          color: _cardShadow,
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
                                // Text(
                                //   _title(),
                                //   textAlign: TextAlign.center,
                                //   style: Theme.of(context)
                                //       .textTheme
                                //       .headlineSmall
                                //       ?.copyWith(
                                //         color: const Color(0xFF3E3028),
                                //         fontWeight: FontWeight.w700,
                                //       ),
                                // ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextInputWidget(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          labelText: 'Email',
          prefixIcon: const Icon(Icons.mail_outline),
        ),
        const Gap(AppSpacing.md),
        if (_isRegister && _otpSent) ...[
          AppTextInputWidget(
            controller: _nameCtrl,
            labelText: 'Name (optional)',
            prefixIcon: const Icon(Icons.person_outline),
          ),
          const Gap(AppSpacing.md),
          AppTextInputWidget(
            controller: _otpCtrl,
            labelText: 'OTP',
            prefixIcon: const Icon(Icons.pin_outlined),
          ),
          const Gap(AppSpacing.md),
        ],
        if (_isReset && _otpSent) ...[
          AppTextInputWidget(
            controller: _otpCtrl,
            labelText: 'OTP',
            prefixIcon: const Icon(Icons.pin_outlined),
          ),
          const Gap(AppSpacing.md),
          AppTextInputWidget(
            controller: _newPasswordCtrl,
            obscureText: _hideNewPassword,
            labelText: 'New password',
            prefixIcon: const Icon(Icons.lock_reset_outlined),
            suffixIcon: IconButton(
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
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
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
            backgroundColor: _primaryButton,
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
            child: const Text('Forgot password?'),
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
            _isRegister ? 'Have an account? Sign in' : 'No account? Register',
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
            child: const Text('Back to sign in'),
          ),
      ],
    );
  }

  // String _title() {
  //   if (_isReset) return 'Reset password';
  //   return _isRegister ? 'Register' : 'Sign in';
  // }

  String _subtitle() {
    if (_isReset) return 'Get a fresh password and return to your bakery cart.';
    if (_isRegister && !_otpSent) {
      return 'Create your bakery account with email OTP.';
    }
    if (_isRegister) return 'Enter the OTP we sent and finish your profile.';
    return 'Welcome back to your daily bread and pastry picks.';
  }

  String _primaryCta() {
    if (_isReset && !_otpSent) return 'Send reset OTP';
    if (_isReset && _otpSent) return 'Confirm new password';
    if (_isRegister && !_otpSent) return 'Send register OTP';
    if (_isRegister && _otpSent) return 'Create account';
    return 'Sign in';
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
          _showSnack(context, 'OTP sent to your email.');
        }
      } else {
        ok = await viewModel.verifyResetPassword(
          email: _emailCtrl.text.trim(),
          otp: _otpCtrl.text.trim(),
          newPassword: _newPasswordCtrl.text,
        );
        if (ok && mounted) {
          _showSnack(context, 'Password reset completed. Please sign in.');
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
          _showSnack(context, 'OTP sent to your email.');
        }
      } else {
        ok = await viewModel.verifyRegister(
          email: _emailCtrl.text.trim(),
          otp: _otpCtrl.text.trim(),
          password: _passwordCtrl.text,
          name: _nameCtrl.text.trim(),
        );
        if (ok && mounted) {
          _showSnack(context, 'Signed in as CUSTOMER.');
        }
      }
      return;
    }

    ok = await viewModel.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
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
                colors: [_heroFadeTop, _heroFadeMiddle, _heroFadeBottom],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppTheme.outlineBeige),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(
                    'BAKERY SHOP',
                    style: TextStyle(
                      color: _brandPillText,
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
