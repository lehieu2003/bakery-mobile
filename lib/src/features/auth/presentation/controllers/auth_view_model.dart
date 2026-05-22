import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';

class AuthState {
  const AuthState({
    this.user,
    this.isBootstrapping = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final User? user;
  final bool isBootstrapping;
  final bool isSubmitting;
  final String? errorMessage;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool clearUser = false,
    bool? isBootstrapping,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthViewModel extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> bootstrap() async {
    state = state.copyWith(isBootstrapping: true, clearError: true);
    try {
      final user = await ref.read(authRepositoryProvider).currentUser();
      state = state.copyWith(
        user: user,
        clearUser: user == null,
        isBootstrapping: false,
      );
    } catch (_) {
      state = state.copyWith(clearUser: true, isBootstrapping: false);
    }
  }

  Future<bool> login({required String email, required String password}) {
    return _submit(() async {
      final user = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      if (!user.isCustomer) {
        throw Exception('Mobile app only supports CUSTOMER accounts.');
      }
      state = state.copyWith(user: user);
      return true;
    });
  }

  Future<bool> sendRegisterOtp({required String email}) {
    return _submit(() async {
      await ref.read(authRepositoryProvider).register(email: email);
      return true;
    });
  }

  Future<bool> verifyRegister({
    required String email,
    required String otp,
    required String password,
    String? name,
  }) {
    return _submit(() async {
      final user = await ref
          .read(authRepositoryProvider)
          .registerVerify(
            email: email,
            otp: otp,
            password: password,
            name: name,
          );
      if (!user.isCustomer) {
        throw Exception('Mobile app only supports CUSTOMER accounts.');
      }
      state = state.copyWith(user: user);
      return true;
    });
  }

  Future<bool> sendResetPasswordOtp({required String email}) {
    return _submit(() async {
      await ref.read(authRepositoryProvider).resetPassword(email: email);
      return true;
    });
  }

  Future<bool> verifyResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return _submit(() async {
      await ref
          .read(authRepositoryProvider)
          .resetPasswordVerify(
            email: email,
            otp: otp,
            newPassword: newPassword,
          );
      return true;
    });
  }

  Future<void> logout() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).logout();
      state = state.copyWith(clearUser: true, clearError: true);
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  Future<bool> updateProfile({String? name, String? phone}) {
    return _submit(() async {
      final user = await ref
          .read(authRepositoryProvider)
          .updateProfile(name: name, phone: phone);
      state = state.copyWith(user: user);
      return true;
    });
  }

  Future<bool> _submit(Future<bool> Function() action) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      return await action();
    } catch (error) {
      state = state.copyWith(
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}
