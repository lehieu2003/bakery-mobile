class AppConfig {
  const AppConfig();

  static const _defaultBaseUrl = 'https://7e0b-125-235-233-231.ngrok-free.app';

  String get baseUrl {
    const value = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: _defaultBaseUrl,
    );
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
