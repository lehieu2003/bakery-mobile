import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:bakery_mobile/src/shared/utils/error_message.dart';

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

/// Longest a sign-out waits for the push token to be revoked.
const Duration _pushUnregisterTimeout = Duration(seconds: 3);

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
      state = state.copyWith(user: user);
      return true;
    });
  }

  Future<bool> loginWithGoogle({GoogleSignIn? googleSignIn}) {
    return _submit(() async {
      final signIn =
          googleSignIn ??
          GoogleSignIn(
            scopes: const ['email', 'profile'],
            serverClientId:
                '89969543194-f45dnqc51lbf20nd60veolpvapgdbgnd.apps.googleusercontent.com',
          );
      final account = await signIn.signIn();
      if (account == null) {
        return false;
      }
      final auth = await account.authentication;
      final user = await ref
          .read(authRepositoryProvider)
          .loginWithGoogle(
            idToken: auth.idToken,
            accessToken: auth.accessToken,
          );
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
    // While the session still works: this phone stops getting the account's
    // pushes. Never holds up the sign-out for long.
    await ref
        .read(pushRegistrationServiceProvider)
        .unregister()
        .timeout(_pushUnregisterTimeout, onTimeout: () {});
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (_) {
      // The API call failed, but the session is dead either way (an expired
      // token the server rejects, or an unreachable backend) — the spec's
      // 401 doctrine is "xóa token → AuthScreen", so logout ALWAYS ends the
      // session client-side. Swallow the error: nothing may block the
      // return to AuthLayout.
    } finally {
      state = state.copyWith(clearUser: true, isSubmitting: false);
    }
  }

  /// Drops a stale error (e.g. from a previous form) before a new flow.
  void clearError() => state = state.copyWith(clearError: true);

  /// Emails the code that confirms account deletion — a code rather than the
  /// password, which Google sign-in accounts do not have.
  Future<bool> sendDeleteAccountOtp() {
    return _submit(() async {
      await ref.read(authRepositoryProvider).requestDeleteAccountOtp();
      return true;
    });
  }

  /// Deletes the account; on success the user is signed out (AppGate
  /// returns to the auth screen). The server's reason lands in errorMessage.
  Future<bool> deleteAccount({required String otp}) {
    return _submit(() async {
      await ref.read(authRepositoryProvider).deleteAccount(otp: otp);
      state = state.copyWith(clearUser: true);
      return true;
    });
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
      state = state.copyWith(errorMessage: userErrorMessage(error));
      return false;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}
