import 'package:flutter/foundation.dart';

import '../models/rustler_device.dart';

class DeviceRegistryService {
  DeviceRegistryService._();

  static final DeviceRegistryService instance = DeviceRegistryService._();

  final ValueNotifier<Map<String, RustlerDevice>> devices =
      ValueNotifier<Map<String, RustlerDevice>>(
    <String, RustlerDevice>{},
  );

  RustlerDevice? getDevice(
    String deviceId,
  ) {
    return devices.value[deviceId];
  }

  void upsertDevice(
    RustlerDevice device,
  ) {
    final updated = Map<String, RustlerDevice>.from(
      devices.value,
    );

    updated[device.id] = device;

    devices.value = updated;
  }

  void removeDevice(
    String deviceId,
  ) {
    final updated = Map<String, RustlerDevice>.from(
      devices.value,
    );

    updated.remove(
      deviceId,
    );

    devices.value = updated;
  }

  void setAvailable(
    String deviceId,
    bool available,
  ) {
    final RustlerDevice? existing = devices.value[deviceId];

    if (existing == null) {
      return;
    }

    upsertDevice(
      existing.copyWith(
        available: available,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void attachEntity({
    required String deviceId,
    required String entityId,
  }) {
    final RustlerDevice? existing = devices.value[deviceId];

    if (existing == null) {
      return;
    }

    final List<String> entityIds = List<String>.from(
      existing.entityIds,
    );

    if (!entityIds.contains(
      entityId,
    )) {
      entityIds.add(
        entityId,
      );
    }

    upsertDevice(
      existing.copyWith(
        entityIds: entityIds,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void detachEntity({
    required String deviceId,
    required String entityId,
  }) {
    final RustlerDevice? existing = devices.value[deviceId];

    if (existing == null) {
      return;
    }

    final List<String> entityIds = List<String>.from(
      existing.entityIds,
    );

    entityIds.remove(
      entityId,
    );

    upsertDevice(
      existing.copyWith(
        entityIds: entityIds,
        updatedAt: DateTime.now(),
      ),
    );
  }

  List<RustlerDevice> get availableDevices {
    return devices.value.values
        .where(
          (device) => device.available,
        )
        .toList();
  }

  void clear() {
    devices.value = <String, RustlerDevice>{};
  }
}
