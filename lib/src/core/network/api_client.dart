import 'dart:convert';

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

  Future<dynamic> delete(String path) async {
    return _request('DELETE', path);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
  }) async {
    final token = await tokenProvider();

    final uri = _buildUri(path, query: query);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    late final http.Response response;
    final payload = body == null ? null : jsonEncode(body);

    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: headers);
      case 'POST':
        response = await http.post(uri, headers: headers, body: payload);
      case 'PUT':
        response = await http.put(uri, headers: headers, body: payload);
      case 'PATCH':
        response = await http.patch(uri, headers: headers, body: payload);
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
      default:
        throw ApiException('Unsupported HTTP method: $method');
    }

    final decoded = _decodeBody(response.body);

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

  Uri _buildUri(String path, {Map<String, dynamic>? query}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$baseUrl$normalizedPath');
    if (query == null || query.isEmpty) {
      return uri;
    }

    return uri.replace(
      queryParameters: query.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
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


