import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/local_http_device.dart';

class LocalDeviceConfigService {
  LocalDeviceConfigService._();

  static final LocalDeviceConfigService instance = LocalDeviceConfigService._();

  static const String _storageKey = 'rustler_gx_local_devices_v1';

  final ValueNotifier<List<LocalHttpDevice>> devices =
      ValueNotifier<List<LocalHttpDevice>>(const <LocalHttpDevice>[]);

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) {
      return;
    }

    final SharedPreferencesAsync preferences = SharedPreferencesAsync();
    final String? raw = await preferences.getString(_storageKey);

    if (raw == null || raw.trim().isEmpty) {
      devices.value = const <LocalHttpDevice>[];
      _loaded = true;
      return;
    }

    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is List) {
        devices.value = decoded
            .whereType<Map>()
            .map(
              (item) => LocalHttpDevice.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where((device) => device.id.isNotEmpty)
            .toList(growable: false);
      }
    } catch (error) {
      debugPrint('Local device config load failed: $error');
      devices.value = const <LocalHttpDevice>[];
    }

    _loaded = true;
  }

  Future<void> saveAll(List<LocalHttpDevice> value) async {
    devices.value = List<LocalHttpDevice>.unmodifiable(value);

    final SharedPreferencesAsync preferences = SharedPreferencesAsync();
    await preferences.setString(
      _storageKey,
      jsonEncode(value.map((device) => device.toJson()).toList()),
    );
  }

  Future<void> upsert(LocalHttpDevice device) async {
    await load();

    final List<LocalHttpDevice> updated =
        List<LocalHttpDevice>.from(devices.value);
    final int index = updated.indexWhere((item) => item.id == device.id);

    if (index >= 0) {
      updated[index] = device;
    } else {
      updated.add(device);
    }

    await saveAll(updated);
  }

  Future<void> remove(String deviceId) async {
    await load();

    await saveAll(
      devices.value.where((device) => device.id != deviceId).toList(),
    );
  }
}
