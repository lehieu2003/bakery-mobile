import 'package:bakery_mobile/src/core/network/api_exception.dart';

/// Shown for failures that carry no message meant for users (programming
/// errors, parse failures): their text is never displayed.
const String unexpectedErrorMessage = 'Đã có lỗi xảy ra. Vui lòng thử lại.';

/// The text to show a user for [error]. [ApiException] messages are already
/// user-facing (the server's 4xx message, or a Vietnamese one for network,
/// timeout and server failures); anything else gets a generic message.
String userErrorMessage(Object error) =>
    error is ApiException ? error.message : unexpectedErrorMessage;
