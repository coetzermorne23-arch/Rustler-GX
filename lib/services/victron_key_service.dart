import 'package:shared_preferences/shared_preferences.dart';

class VictronKeyService {
  VictronKeyService._();

  static final VictronKeyService instance = VictronKeyService._();

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  static const String _knownDevicesKey = 'victron_known_devices';

  String _storageKey(String deviceId) {
    return 'victron_encryption_key_$deviceId';
  }

  // =========================================================
  // ENCRYPTION KEYS
  // =========================================================

  Future<String?> getKey(
    String deviceId,
  ) async {
    return _preferences.getString(
      _storageKey(deviceId),
    );
  }

  Future<void> saveKey({
    required String deviceId,
    required String encryptionKey,
  }) async {
    final String normalizedKey = encryptionKey
        .replaceAll(' ', '')
        .replaceAll(':', '')
        .trim()
        .toLowerCase();

    if (!RegExp(r'^[0-9a-f]{32}$').hasMatch(normalizedKey)) {
      throw const FormatException(
        'Encryption key must contain exactly '
        '32 hexadecimal characters.',
      );
    }

    await _preferences.setString(
      _storageKey(deviceId),
      normalizedKey,
    );

    // A device with a saved encryption key is
    // automatically considered a known device.
    await rememberDevice(deviceId);
  }

  Future<void> removeKey(
    String deviceId,
  ) async {
    await _preferences.remove(
      _storageKey(deviceId),
    );
  }

  Future<bool> hasKey(
    String deviceId,
  ) async {
    final String? key = await getKey(deviceId);

    return key != null && key.isNotEmpty;
  }

  // =========================================================
  // KNOWN / TRUSTED DEVICES
  // =========================================================

  Future<Set<String>> getKnownDevices() async {
    final List<String>? stored = await _preferences.getStringList(
      _knownDevicesKey,
    );

    if (stored == null) {
      return <String>{};
    }

    return stored.toSet();
  }

  Future<bool> isKnownDevice(
    String deviceId,
  ) async {
    final Set<String> devices = await getKnownDevices();

    return devices.contains(deviceId);
  }

  Future<void> rememberDevice(
    String deviceId,
  ) async {
    final Set<String> devices = await getKnownDevices();

    if (devices.add(deviceId)) {
      await _preferences.setStringList(
        _knownDevicesKey,
        devices.toList(),
      );
    }
  }

  Future<void> forgetDevice(
    String deviceId,
  ) async {
    final Set<String> devices = await getKnownDevices();

    devices.remove(deviceId);

    await _preferences.setStringList(
      _knownDevicesKey,
      devices.toList(),
    );

    // Forgetting a device also removes its
    // Instant Readout encryption key.
    await removeKey(deviceId);
  }

  Future<void> clearKnownDevices() async {
    final Set<String> devices = await getKnownDevices();

    for (final String deviceId in devices) {
      await removeKey(deviceId);
    }

    await _preferences.remove(
      _knownDevicesKey,
    );
  }
}
