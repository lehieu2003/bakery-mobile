import 'dart:convert';
import 'dart:io';

import 'package:bakery_mobile/src/core/network/api_exception.dart';

/// Raw text of `test/fixtures/<name>` (e.g. `fixture('blog/posts_success.json')`).
String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

/// Decoded fixture: the full API envelope `{ success, data | error }`.
Map<String, dynamic> fixtureJson(String name) =>
    jsonDecode(fixture(name)) as Map<String, dynamic>;

/// What `ApiClient` returns for a success envelope: its `data` payload.
Object? fixtureData(String name) => fixtureJson(name)['data'];

/// What `ApiClient` throws for an error envelope (`{ success: false, error }`).
ApiException fixtureError(String name, {int statusCode = 500}) => ApiException(
  (fixtureJson(name)['error'] ?? 'Request failed').toString(),
  statusCode: statusCode,
);

/// Shared error envelopes in `test/fixtures/common/`.
const String error500 = 'common/error_500.json';
const String error401 = 'common/error_401.json';
