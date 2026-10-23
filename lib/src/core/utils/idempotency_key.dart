import 'dart:math';

/// Bytes of randomness in a key: 128 bits, as in a UUID v4.
const int _idempotencyKeyBytes = 16;

/// A random key for one checkout attempt, sent as `Idempotency-Key` so that
/// bakery-web returns the order a retried request already created. 32 hex
/// characters, within the server's `[A-Za-z0-9_-]{8,128}` rule.
String newIdempotencyKey([Random? random]) {
  final source = random ?? Random.secure();
  return List.generate(
    _idempotencyKeyBytes,
    (_) => source.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}
