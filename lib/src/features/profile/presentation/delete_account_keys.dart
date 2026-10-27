import 'package:flutter/widgets.dart';

/// Widget keys of the delete-account flow (used by tests and finders).
abstract final class DeleteAccountKeys {
  static const entry = Key('profile.deleteAccount');
  static const otp = Key('deleteAccount.otp');
  static const sendOtp = Key('deleteAccount.sendOtp');
  static const confirm = Key('deleteAccount.confirm');
  static const submit = Key('deleteAccount.submit');
  static const error = Key('deleteAccount.error');
}
