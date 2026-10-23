/// What went wrong with a request, so callers and UI can react by cause
/// (e.g. show "offline" or keep an idempotency key) instead of by message.
enum ApiErrorKind {
  /// The request never got an answer: no connection, DNS, refused, TLS.
  network,

  /// No answer within the client timeout — the server may still act on it.
  timeout,

  /// The server failed (5xx) or answered with something that is not the
  /// API's JSON (e.g. a proxy's HTML error page).
  server,

  /// 401: the session is missing, expired or revoked.
  unauthorized,

  /// Any other answered error (4xx): the server's message is meant for users.
  client,
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, ApiErrorKind? kind})
    : kind = kind ?? _kindFor(statusCode);

  final String message;
  final int? statusCode;
  final ApiErrorKind kind;

  /// The request may not have reached the server; retrying is safe and the
  /// app is likely offline.
  bool get isConnectivityIssue =>
      kind == ApiErrorKind.network || kind == ApiErrorKind.timeout;

  static ApiErrorKind _kindFor(int? statusCode) {
    if (statusCode == null) return ApiErrorKind.network;
    if (statusCode == 401) return ApiErrorKind.unauthorized;
    if (statusCode >= 500) return ApiErrorKind.server;
    return ApiErrorKind.client;
  }

  @override
  String toString() => message;
}
