import '../models/rustler_device.dart';
import '../models/rustler_entity.dart';
import 'device_registry_service.dart';
import 'entity_service.dart';

class DeviceEntityLinkService {
  DeviceEntityLinkService._();

  static final DeviceEntityLinkService instance = DeviceEntityLinkService._();

  final DeviceRegistryService devices = DeviceRegistryService.instance;

  final EntityService entities = EntityService.instance;

  void registerDevice(
    RustlerDevice device,
  ) {
    devices.upsertDevice(
      device,
    );
  }

  void publishEntity({
    required String deviceId,
    required RustlerEntity entity,
  }) {
    entities.upsert(
      entity,
    );

    devices.attachEntity(
      deviceId: deviceId,
      entityId: entity.id,
    );
  }

  List<RustlerEntity> entitiesForDevice(
    String deviceId,
  ) {
    final RustlerDevice? device = devices.getDevice(
      deviceId,
    );

    if (device == null) {
      return <RustlerEntity>[];
    }

    final List<RustlerEntity> result = <RustlerEntity>[];

    for (final String entityId in device.entityIds) {
      final RustlerEntity? entity = entities.get(
        entityId,
      );

      if (entity != null) {
        result.add(
          entity,
        );
      }
    }

    return result;
  }

  void setDeviceAvailability(
    String deviceId,
    bool available,
  ) {
    devices.setAvailable(
      deviceId,
      available,
    );

    final RustlerDevice? device = devices.getDevice(
      deviceId,
    );

    if (device == null) {
      return;
    }

    for (final String entityId in device.entityIds) {
      final RustlerEntity? entity = entities.get(
        entityId,
      );

      if (entity == null) {
        continue;
      }

      entities.upsert(
        entity.copyWith(
          available: available,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }
}
