import 'package:bakery_mobile/src/core/config/app_config.dart';

String resolveImageUrl(String? rawUrl) {
  final raw = (rawUrl ?? '').trim();
  if (raw.isEmpty) return '';

  final base = const AppConfig().baseUrl;
  final uri = Uri.tryParse(raw);
  if (uri != null && uri.hasScheme) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'http' || scheme == 'https') {
      return raw;
    }
    if (scheme == 'file') {
      final filePath = uri.path.trim();
      if (filePath.isEmpty) return '';
      final normalized = filePath.startsWith('/') ? filePath : '/$filePath';
      return '$base$normalized';
    }
    return raw;
  }
  if (raw.startsWith('//')) {
    return 'https:$raw';
  }

  if (raw.startsWith('/')) {
    return '$base$raw';
  }
  return '$base/$raw';
}
