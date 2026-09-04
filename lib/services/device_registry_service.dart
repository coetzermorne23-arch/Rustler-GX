import 'package:flutter/foundation.dart';

import '../models/rustler_device.dart';

class DeviceRegistryService {
  DeviceRegistryService._();

  static final DeviceRegistryService instance = DeviceRegistryService._();

  final ValueNotifier<Map<String, RustlerDevice>> devices =
      ValueNotifier<Map<String, RustlerDevice>>(<String, RustlerDevice>{});

  void upsert(RustlerDevice device) {
    final Map<String, RustlerDevice> updated =
        Map<String, RustlerDevice>.from(devices.value);
    updated[device.id] = device;
    devices.value = updated;
  }

  void upsertDevice(RustlerDevice device) {
    upsert(device);
  }

  void remove(String deviceId) {
    if (!devices.value.containsKey(deviceId)) {
      return;
    }

    final Map<String, RustlerDevice> updated =
        Map<String, RustlerDevice>.from(devices.value);
    updated.remove(deviceId);
    devices.value = updated;
  }

  RustlerDevice? getDevice(String deviceId) => devices.value[deviceId];

  List<RustlerDevice> bySource(String source) {
    return devices.value.values
        .where((device) => device.source == source)
        .toList(growable: false);
  }

  List<RustlerDevice> byType(RustlerDeviceType type) {
    return devices.value.values
        .where((device) => device.type == type)
        .toList(growable: false);
  }

  void setAvailable(String deviceId, bool available) {
    final RustlerDevice? device = devices.value[deviceId];
    if (device == null) {
      return;
    }

    upsert(
      device.copyWith(
        available: available,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void attachEntity(String deviceId, String entityId) {
    final RustlerDevice? device = devices.value[deviceId];
    if (device == null || device.entityIds.contains(entityId)) {
      return;
    }

    upsert(
      device.copyWith(
        entityIds: <String>[...device.entityIds, entityId],
        updatedAt: DateTime.now(),
      ),
    );
  }

  void detachEntity(String deviceId, String entityId) {
    final RustlerDevice? device = devices.value[deviceId];
    if (device == null) {
      return;
    }

    upsert(
      device.copyWith(
        entityIds: device.entityIds
            .where((id) => id != entityId)
            .toList(growable: false),
        updatedAt: DateTime.now(),
      ),
    );
  }

  void clearSource(String source) {
    final Map<String, RustlerDevice> updated =
        Map<String, RustlerDevice>.from(devices.value)
          ..removeWhere((_, device) => device.source == source);
    devices.value = updated;
  }
}
