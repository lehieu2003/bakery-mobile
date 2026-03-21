import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isRegister = false;
  bool _otpSent = false;
  bool _isReset = false;

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
    final viewModel = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text(_title())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          if (_isRegister && _otpSent) ...[
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _otpCtrl,
              decoration: const InputDecoration(labelText: 'OTP'),
            ),
            const SizedBox(height: 12),
          ],
          if (_isReset && _otpSent) ...[
            TextField(
              controller: _otpCtrl,
              decoration: const InputDecoration(labelText: 'OTP'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 12),
          ],
          if (!_isReset && (!_isRegister || _otpSent)) ...[
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: _isRegister ? 'Password' : 'Password',
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (viewModel.errorMessage != null) ...[
            Text(
              viewModel.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton(
            onPressed: viewModel.isSubmitting ? null : _submit,
            child: viewModel.isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_primaryCta()),
          ),
          const SizedBox(height: 12),
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
      ),
    );
  }

  String _title() {
    if (_isReset) return 'Reset password';
    return _isRegister ? 'Register' : 'Sign in';
  }

  String _primaryCta() {
    if (_isReset && !_otpSent) return 'Send reset OTP';
    if (_isReset && _otpSent) return 'Confirm new password';
    if (_isRegister && !_otpSent) return 'Send register OTP';
    if (_isRegister && _otpSent) return 'Create account';
    return 'Sign in';
  }

  Future<void> _submit() async {
    final viewModel = context.read<AuthViewModel>();

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

    if (ok && mounted) {
      _showSnack(context, 'Welcome back.');
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}


