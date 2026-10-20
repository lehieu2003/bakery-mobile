/// Shared defensive JSON coercion helpers for admin DTOs.
library;

/// Coerces a numeric field that may arrive as `num`, numeric `String` (or
/// be missing) into a [num]; unparseable values fall back to 0.
num asNum(dynamic value) {
  if (value is num) return value;
  if (value is String) {
    final parsed = num.tryParse(value);
    if (parsed != null) return parsed;
  }
  return 0;
}

/// Parses a raw JSON list of objects with [fromJson], skipping any entries
/// that are not `Map<String, dynamic>`; non-list input yields an empty list.
List<T> parseJsonList<T>(
  dynamic raw,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (raw is List<dynamic>) {
    return raw.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }
  return const [];
}
