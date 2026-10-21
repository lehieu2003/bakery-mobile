import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:bakery_mobile/src/core/network/api_exception.dart';

typedef TokenProvider = Future<String?> Function();

class ApiClient {
  ApiClient({required this.baseUrl, required this.tokenProvider});

  final String baseUrl;
  final TokenProvider tokenProvider;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    return _request('GET', path, query: query);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    return _request('POST', path, body: body);
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
  }) async {
    final uri = _buildUri(path, query: query);
    final payload = body == null ? null : jsonEncode(body);

    final token = await tokenProvider();
    var response = await _send(method, uri, token, payload);
    if (response.statusCode == 401 && token != null && token.isNotEmpty) {
      // The session may have been rotated while this request was in flight
      // (the server revokes the old token immediately). Retry once with the
      // current token instead of surfacing a spurious 401 → logout. Safe for
      // writes too: a 401 is decided before the handler runs.
      final current = await tokenProvider();
      if (current != null && current.isNotEmpty && current != token) {
        response = await _send(method, uri, current, payload);
      }
    }

    final decoded = _decodeBody(response.body);
    if (kDebugMode) {
      final preview = response.body.length > 220
          ? '${response.body.substring(0, 220)}...'
          : response.body;
      debugPrint('[API] <- ${response.statusCode} ${uri.path} body=$preview');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _extractError(decoded),
        statusCode: response.statusCode,
      );
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
  ) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    if (kDebugMode) {
      final tokenPreview = token == null || token.isEmpty
          ? 'none'
          : '${token.substring(0, token.length > 12 ? 12 : token.length)}...';
      debugPrint(
        '[API] $method ${uri.path}${uri.hasQuery ? '?${uri.query}' : ''} token=$tokenPreview',
      );
    }
    return switch (method) {
      'GET' => http.get(uri, headers: headers),
      'POST' => http.post(uri, headers: headers, body: payload),
      'PUT' => http.put(uri, headers: headers, body: payload),
      'PATCH' => http.patch(uri, headers: headers, body: payload),
      'DELETE' => http.delete(uri, headers: headers, body: payload),
      _ => throw ApiException('Unsupported HTTP method: $method'),
    };
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
      return <String, dynamic>{'message': body};
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
