import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// This install's device id, sent to bakery-web with every request
/// (`x-device-id`). The server uses it to keep admin accounts to one trusted
/// phone: another phone has to confirm with an emailed code. Created once,
/// kept in the secure store; a reinstall is a new device.
class DeviceIdStorage {
  DeviceIdStorage({FlutterSecureStorage? secureStorage, Random? random})
    : _secure = secureStorage ?? const FlutterSecureStorage(),
      _random = random ?? Random.secure();

  static const _key = 'bakery_device_id';

  final FlutterSecureStorage _secure;
  final Random _random;
  Future<String>? _id;

  Future<String> read() => _id ??= _loadOrCreate();

  Future<String> _loadOrCreate() async {
    final stored = await _secure.read(key: _key);
    if (stored != null && stored.length >= 16) return stored;
    final bytes = List<int>.generate(24, (_) => _random.nextInt(256));
    final id = base64Url.encode(bytes).replaceAll('=', '');
    await _secure.write(key: _key, value: id);
    return id;
  }
}
