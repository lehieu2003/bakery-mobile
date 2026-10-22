import 'dart:async';

import 'package:bakery_mobile/src/core/network/api_client.dart';

import 'fixture.dart';

/// One request the code under test sent through [FakeApiClient].
class ApiCall {
  const ApiCall(this.method, this.path, {this.query, this.body});

  final String method;
  final String path;
  final Map<String, dynamic>? query;
  final Object? body;

  @override
  String toString() => '$method $path ${query ?? ''}${body ?? ''}';
}

typedef ApiResponder = FutureOr<Object?> Function(ApiCall call);

/// In-memory [ApiClient]: the real services, DTO parsing, repositories and
/// view models run on top of it, so tests cover the whole data path.
///
/// - Responses are stubbed per `METHOD path` (query/body are recorded, not
///   matched) — usually from a fixture file.
/// - Every request is recorded in [calls].
/// - [hold] parks a response so a test can observe the loading state.
class FakeApiClient extends ApiClient {
  FakeApiClient()
    : super(baseUrl: 'http://fake.test', tokenProvider: () async => null);

  final List<ApiCall> calls = [];
  final Map<String, ApiResponder> _routes = {};

  static String _key(String method, String path) => '$method $path';

  void stub(String method, String path, ApiResponder responder) =>
      _routes[_key(method, path)] = responder;

  /// Responds with the `data` of a success fixture.
  void stubFixture(String method, String path, String fixtureName) =>
      stub(method, path, (_) => fixtureData(fixtureName));

  /// Throws the [ApiException] described by an error fixture.
  void stubError(
    String method,
    String path, {
    String fixtureName = error500,
    int statusCode = 500,
  }) => stub(
    method,
    path,
    (_) => throw fixtureError(fixtureName, statusCode: statusCode),
  );

  /// Delays the currently stubbed response until the returned completer
  /// completes (call [Completer.complete] to release it).
  Completer<void> hold(String method, String path) {
    final gate = Completer<void>();
    final inner = _routes[_key(method, path)];
    stub(method, path, (call) async {
      await gate.future;
      return inner == null ? null : await inner(call);
    });
    return gate;
  }

  List<ApiCall> callsTo(String method, String path) =>
      calls.where((c) => c.method == method && c.path == path).toList();

  Future<dynamic> _handle(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
  }) async {
    final call = ApiCall(method, path, query: query, body: body);
    calls.add(call);
    final responder = _routes[_key(method, path)];
    if (responder == null) {
      throw StateError('FakeApiClient: no stub for $method $path');
    }
    return await responder(call);
  }

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _handle('GET', path, query: query);

  @override
  Future<dynamic> post(String path, {Object? body}) =>
      _handle('POST', path, body: body);

  @override
  Future<dynamic> put(String path, {Object? body}) =>
      _handle('PUT', path, body: body);

  @override
  Future<dynamic> patch(String path, {Object? body}) =>
      _handle('PATCH', path, body: body);

  @override
  Future<dynamic> delete(String path, {Object? body}) =>
      _handle('DELETE', path, body: body);
}
