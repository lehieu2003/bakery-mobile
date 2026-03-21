import 'package:flutter/foundation.dart';

import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:bakery_mobile/src/features/auth/data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._authRepository);

  final AuthRepository _authRepository;

  User? _user;
  bool _isBootstrapping = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isBootstrapping => _isBootstrapping;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> bootstrap() async {
    _isBootstrapping = true;
    notifyListeners();

    try {
      _user = await _authRepository.currentUser();
    } finally {
      _isBootstrapping = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    return _submit(() async {
      final user = await _authRepository.login(
        email: email,
        password: password,
      );
      if (!user.isCustomer) {
        throw Exception('Mobile app only supports CUSTOMER accounts.');
      }
      _user = user;
      return true;
    });
  }

  Future<bool> sendRegisterOtp({required String email}) async {
    return _submit(() async {
      await _authRepository.register(email: email);
      return true;
    });
  }

  Future<bool> verifyRegister({
    required String email,
    required String otp,
    required String password,
    String? name,
  }) async {
    return _submit(() async {
      final user = await _authRepository.registerVerify(
        email: email,
        otp: otp,
        password: password,
        name: name,
      );
      if (!user.isCustomer) {
        throw Exception('Mobile app only supports CUSTOMER accounts.');
      }
      _user = user;
      return true;
    });
  }

  Future<bool> sendResetPasswordOtp({required String email}) {
    return _submit(() async {
      await _authRepository.resetPassword(email: email);
      return true;
    });
  }

  Future<bool> verifyResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return _submit(() async {
      await _authRepository.resetPasswordVerify(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      return true;
    });
  }

  Future<void> logout() async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _authRepository.logout();
      _user = null;
      _errorMessage = null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> _submit(Future<bool> Function() action) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await action();
      return result;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}


