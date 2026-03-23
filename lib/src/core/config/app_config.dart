import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig();

  String get baseUrl {
    final runtimeValue = dotenv.env['API_BASE_URL'] ?? '';
    const compileTimeValue = String.fromEnvironment('API_BASE_URL');
    final value = runtimeValue.isNotEmpty ? runtimeValue : compileTimeValue;
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
