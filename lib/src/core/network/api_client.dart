import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:bakery_mobile/src/core/network/api_exception.dart';

/// Debug logging only: characters of a response body / bearer token shown.
const int _bodyPreviewLength = 220;
const int _tokenPreviewLength = 12;

/// Longer than bakery-web's own payment-gateway timeout (15s) so a slow but
/// successful checkout is not cut off client-side.
const Duration defaultRequestTimeout = Duration(seconds: 30);

/// Marks a body that was not JSON (kept for 2xx callers, never shown).
const String _rawBodyKey = '_raw';

/// User-facing messages for failures the server did not explain itself.
const String networkErrorMessage =
    'Không có kết nối mạng. Vui lòng kiểm tra Wi‑Fi/4G rồi thử lại.';
const String timeoutErrorMessage =
    'Máy chủ phản hồi quá lâu. Vui lòng kiểm tra kết nối và thử lại.';
const String serverErrorMessage =
    'Máy chủ đang gặp sự cố. Vui lòng thử lại sau ít phút.';

typedef TokenProvider = Future<String?> Function();
typedef HeadersProvider = Future<Map<String, String>> Function();

class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.tokenProvider,
    this.requestTimeout = defaultRequestTimeout,
    this.defaultHeaders,
  });

  final String baseUrl;
  final TokenProvider tokenProvider;
  final Duration requestTimeout;

  /// Sent with every request (the device id bakery-web checks for admins).
  final HeadersProvider? defaultHeaders;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    return _request('GET', path, query: query);
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    return _request('POST', path, body: body, headers: headers);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    return _request('PUT', path, body: body);
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    return _request('PATCH', path, body: body);
  }

  Future<dynamic> delete(String path, {Object? body}) async {
    return _request('DELETE', path, body: body);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, query: query);
    final payload = body == null ? null : jsonEncode(body);
    final provided = defaultHeaders;
    if (provided != null) {
      headers = {...await provided(), ...?headers};
    }

    final token = await tokenProvider();
    var response = await _send(method, uri, token, payload, headers);
    if (response.statusCode == 401 && token != null && token.isNotEmpty) {
      // The session may have been rotated while this request was in flight
      // (the server revokes the old token immediately). Retry once with the
      // current token instead of surfacing a spurious 401 → logout. Safe for
      // writes too: a 401 is decided before the handler runs.
      final current = await tokenProvider();
      if (current != null && current.isNotEmpty && current != token) {
        response = await _send(method, uri, current, payload, headers);
      }
    }

    final decoded = _decodeBody(response.body);
    if (kDebugMode) {
      final preview = response.body.length > _bodyPreviewLength
          ? '${response.body.substring(0, _bodyPreviewLength)}...'
          : response.body;
      debugPrint('[API] <- ${response.statusCode} ${uri.path} body=$preview');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _errorFor(response.statusCode, decoded);
    }

    if (decoded is Map<String, dynamic>) {
      if (decoded['success'] == false) {
        throw ApiException(
          _extractError(decoded),
          statusCode: response.statusCode,
        );
      }
      if (decoded.containsKey('data')) {
        return decoded['data'];
      }
    }

    return decoded;
  }

  Future<http.Response> _send(
    String method,
    Uri uri,
    String? token,
    String? payload,
    Map<String, String>? extraHeaders,
  ) async {
    final headers = <String, String>{
      ...?extraHeaders,
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    if (kDebugMode) {
      final tokenPreview = token == null || token.isEmpty
          ? 'none'
          : '${token.substring(0, min(token.length, _tokenPreviewLength))}...';
      debugPrint(
        '[API] $method ${uri.path}${uri.hasQuery ? '?${uri.query}' : ''} token=$tokenPreview',
      );
    }
    final request = switch (method) {
      'GET' => http.get(uri, headers: headers),
      'POST' => http.post(uri, headers: headers, body: payload),
      'PUT' => http.put(uri, headers: headers, body: payload),
      'PATCH' => http.patch(uri, headers: headers, body: payload),
      'DELETE' => http.delete(uri, headers: headers, body: payload),
      _ => throw ApiException('Unsupported HTTP method: $method'),
    };
    // Transport failures surface as ApiException like server errors, so
    // callers show a readable message instead of a raw exception and never
    // wait on a hung request forever.
    try {
      return await request.timeout(requestTimeout);
    } on TimeoutException {
      throw ApiException(timeoutErrorMessage, kind: ApiErrorKind.timeout);
    } catch (error) {
      // ClientException covers sockets and DNS; TLS handshake failures (e.g.
      // a captive Wi‑Fi portal) arrive as other exception types. Programming
      // errors are not transport failures.
      if (error is Error) rethrow;
      throw ApiException(networkErrorMessage, kind: ApiErrorKind.network);
    }
  }

  /// Error for a non-2xx answer. A 5xx — or any body that is not the API's
  /// JSON, like a proxy's HTML 502 page — gets a generic message: neither
  /// raw markup nor the server's English internals reach the user. A 4xx
  /// keeps the server's message, which is written for users.
  ApiException _errorFor(int statusCode, dynamic decoded) {
    if (statusCode >= 500) {
      return ApiException(serverErrorMessage, statusCode: statusCode);
    }
    final isApiJson =
        decoded is Map<String, dynamic> && !decoded.containsKey(_rawBodyKey);
    if (!isApiJson) {
      // A non-JSON 4xx comes from infrastructure (proxy, CDN), not the API.
      return ApiException(
        serverErrorMessage,
        statusCode: statusCode,
        kind: ApiErrorKind.server,
      );
    }
    return ApiException(_extractError(decoded), statusCode: statusCode);
  }

  Uri _buildUri(String path, {Map<String, dynamic>? query}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$baseUrl$normalizedPath');
    if (query == null || query.isEmpty) {
      return uri;
    }

    final queryParametersAll = <String, List<String>>{};
    for (final entry in query.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is Iterable) {
        queryParametersAll[entry.key] = value
            .where((item) => item != null)
            .map((item) => item.toString())
            .toList();
      } else {
        queryParametersAll[entry.key] = [value.toString()];
      }
    }

    final queryString = queryParametersAll.entries
        .expand(
          (entry) => entry.value.map(
            (value) =>
                '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(value)}',
          ),
        )
        .join('&');

    return uri.replace(query: queryString.isEmpty ? null : queryString);
  }

  dynamic _decodeBody(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      return jsonDecode(body);
    } catch (_) {
      return <String, dynamic>{_rawBodyKey: body};
    }
  }

  String _extractError(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'];
      final message = decoded['message'];
      if (error is String && error.isNotEmpty) {
        return error;
      }
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    return 'Request failed';
  }
}
