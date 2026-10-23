import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/config/app_config.dart';
import 'package:bakery_mobile/src/core/network/connectivity.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/navigation/presentation/screens/app_gate.dart';
import 'package:bakery_mobile/src/shared/widgets/offline_banner_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const config = AppConfig();
  // `.env` is a per-machine dev override; production reads only the values
  // compiled in from config/prod.json.
  if (!config.isProd) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}
  }
  if (config.baseUrl.isEmpty) {
    throw StateError(
      'API_BASE_URL is empty — build with '
      '--dart-define-from-file=config/${config.flavor.name}.json',
    );
  }
  runApp(const ProviderScope(child: BakeryMobileApp()));
}

class BakeryMobileApp extends StatelessWidget {
  const BakeryMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    const config = AppConfig();
    return MaterialApp(
      title: 'Phương Loan Bakery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (context, child) {
        Widget app = ConnectivityWatcher(
          child: OfflineBannerWidget(child: child ?? const SizedBox.shrink()),
        );
        // Non-production builds carry a corner ribbon so they are never
        // mistaken for the store app.
        if (!config.isProd) {
          app = Banner(
            message: config.flavor.name.toUpperCase(),
            location: BannerLocation.topEnd,
            child: app,
          );
        }
        return app;
      },
      home: const AppGate(),
    );
  }
}
