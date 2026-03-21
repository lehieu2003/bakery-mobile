import 'package:bakery_mobile/src/core/config/app_config.dart';

String resolveImageUrl(String? rawUrl) {
  final raw = (rawUrl ?? '').trim();
  if (raw.isEmpty) return '';

  final uri = Uri.tryParse(raw);
  if (uri != null && uri.hasScheme) {
    return raw;
  }
  if (raw.startsWith('//')) {
    return 'https:$raw';
  }

  final base = const AppConfig().baseUrl;
  if (raw.startsWith('/')) {
    return '$base$raw';
  }
  return '$base/$raw';
}
