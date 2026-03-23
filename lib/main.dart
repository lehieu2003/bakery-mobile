import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/navigation/presentation/screens/app_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}
  runApp(const ProviderScope(child: BakeryMobileApp()));
}

class BakeryMobileApp extends StatelessWidget {
  const BakeryMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bakery Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AppGate(),
    );
  }
}
