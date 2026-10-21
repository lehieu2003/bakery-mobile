import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Build environment, chosen at compile time with
/// `--dart-define-from-file=config/<flavor>.json` (key `FLAVOR`).
enum AppFlavor { dev, prod }

/// Unknown or missing names resolve to [AppFlavor.dev] so a build without
/// the define can never silently behave as production.
AppFlavor parseFlavor(String name) =>
    name == 'prod' ? AppFlavor.prod : AppFlavor.dev;

/// Picks the API base URL for [flavor]:
/// - prod: only the compile-time [defined] value — the bundled `.env` asset
///   is ignored so a developer's local URL can never ship;
/// - dev: a non-empty [envFile] (`.env`, per-machine: emulator vs device)
///   overrides the flavor default.
/// A trailing slash is trimmed.
@visibleForTesting
String resolveBaseUrl({
  required AppFlavor flavor,
  required String defined,
  required String? envFile,
}) {
  final local = envFile ?? '';
  final value = flavor == AppFlavor.dev && local.isNotEmpty ? local : defined;
  return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
}

class AppConfig {
  const AppConfig();

  static const String _flavorName = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'dev',
  );
  static const String _definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  AppFlavor get flavor => parseFlavor(_flavorName);

  bool get isProd => flavor == AppFlavor.prod;

  String get baseUrl => resolveBaseUrl(
    flavor: flavor,
    defined: _definedBaseUrl,
    envFile: dotenv.isInitialized ? dotenv.env['API_BASE_URL'] : null,
  );
}
