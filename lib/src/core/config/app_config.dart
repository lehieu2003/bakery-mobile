class AppConfig {
  const AppConfig();

  static const _defaultBaseUrl = 'http://10.0.2.2:3000';

  String get baseUrl {
    const value = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: _defaultBaseUrl,
    );
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
