import '../models/rustler_device.dart';
import '../models/rustler_entity.dart';
import 'device_registry_service.dart';
import 'entity_service.dart';

class DeviceEntityLinkService {
  DeviceEntityLinkService._();

  static final DeviceEntityLinkService instance = DeviceEntityLinkService._();

  final DeviceRegistryService _devices = DeviceRegistryService.instance;
  final EntityService _entities = EntityService.instance;

  EntityService get entities => _entities;

  void registerDevice(RustlerDevice device) {
    _devices.upsert(device);
  }

  void publishEntity({
    required String deviceId,
    required RustlerEntity entity,
  }) {
    _entities.upsert(entity);
    _devices.attachEntity(deviceId, entity.id);
  }

  void removeEntity({
    required String deviceId,
    required String entityId,
  }) {
    _entities.remove(entityId);
    _devices.detachEntity(deviceId, entityId);
  }

  List<RustlerEntity> entitiesForDevice(String deviceId) {
    final RustlerDevice? device = _devices.getDevice(deviceId);
    if (device == null) {
      return const <RustlerEntity>[];
    }

    return device.entityIds
        .map(_entities.getEntity)
        .whereType<RustlerEntity>()
        .toList(growable: false);
  }

  void setDeviceAvailability(String deviceId, bool available) {
    _devices.setAvailable(deviceId, available);

    final RustlerDevice? device = _devices.getDevice(deviceId);
    if (device == null) {
      return;
    }

    for (final String entityId in device.entityIds) {
      final RustlerEntity? entity = _entities.getEntity(entityId);
      if (entity == null) {
        continue;
      }

      _entities.upsert(
        entity.copyWith(
          available: available,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }
}
