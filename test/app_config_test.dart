import 'package:bakery_mobile/src/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseFlavor', () {
    test('known names map to their flavor', () {
      expect(parseFlavor('dev'), AppFlavor.dev);
      expect(parseFlavor('prod'), AppFlavor.prod);
    });

    test('missing or unknown name falls back to dev (never prod)', () {
      expect(parseFlavor(''), AppFlavor.dev);
      expect(parseFlavor('production'), AppFlavor.dev);
    });
  });

  group('resolveBaseUrl', () {
    test('prod uses the compile-time value and ignores .env', () {
      expect(
        resolveBaseUrl(
          flavor: AppFlavor.prod,
          defined: 'https://phuong-loan-bakery.vercel.app/',
          envFile: 'http://10.0.2.2:3001',
        ),
        'https://phuong-loan-bakery.vercel.app',
      );
    });

    test('dev lets a local .env override the flavor default', () {
      expect(
        resolveBaseUrl(
          flavor: AppFlavor.dev,
          defined: 'http://10.0.2.2:3001',
          envFile: 'http://192.168.1.20:3001',
        ),
        'http://192.168.1.20:3001',
      );
    });

    test('dev without .env value uses the compile-time value', () {
      expect(
        resolveBaseUrl(
          flavor: AppFlavor.dev,
          defined: 'http://10.0.2.2:3001',
          envFile: '',
        ),
        'http://10.0.2.2:3001',
      );
      expect(
        resolveBaseUrl(
          flavor: AppFlavor.dev,
          defined: 'http://10.0.2.2:3001',
          envFile: null,
        ),
        'http://10.0.2.2:3001',
      );
    });
  });
}
