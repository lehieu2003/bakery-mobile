import 'package:flutter/foundation.dart';

class ParseUtils {
  static double toDouble(dynamic value, {required String field}) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    if (kDebugMode) {
      debugPrint(
        '[PARSE] Invalid double at "$field": value=$value (type=${value.runtimeType})',
      );
    }
    return 0;
  }

  static int toInt(dynamic value, {required String field}) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    if (kDebugMode) {
      debugPrint(
        '[PARSE] Invalid int at "$field": value=$value (type=${value.runtimeType})',
      );
    }
    return 0;
  }
}
