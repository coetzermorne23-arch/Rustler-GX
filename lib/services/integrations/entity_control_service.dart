import '../../models/entity_sources.dart';
import '../../models/local_http_device.dart';
import '../../models/rustler_entity.dart';
import 'esp_http_service.dart';
import 'local_device_config_service.dart';
import 'sonoff_diy_service.dart';
import 'tuya_bridge_service.dart';

class EntityControlService {
  EntityControlService._();

  static final EntityControlService instance = EntityControlService._();

  final LocalDeviceConfigService _configs = LocalDeviceConfigService.instance;

  bool canControl(RustlerEntity entity) {
    if (!entity.available) return false;

    switch (entity.source) {
      case EntitySources.sonoff:
        return entity.id.endsWith('.switch');
      case EntitySources.esp:
      case EntitySources.tuya:
        return entity.type == RustlerEntityType.switchEntity ||
            entity.type == RustlerEntityType.relay ||
            entity.type == RustlerEntityType.binarySensor ||
            entity.type == RustlerEntityType.number;
      default:
        return false;
    }
  }

  Future<void> setValue(RustlerEntity entity, dynamic value) async {
    await _configs.load();

    final LocalHttpDevice device = _findConfig(entity);
    final String key = _entityKey(entity, device);

    switch (entity.source) {
      case EntitySources.sonoff:
        if (value is! bool) {
          throw ArgumentError('SONOFF switch control expects a boolean value.');
        }
        await SonoffDiyService.instance.setSwitch(device, value);
        return;

      case EntitySources.esp:
        await EspHttpService.instance.setEntityValue(
          device: device,
          entityKey: key,
          value: value,
        );
        return;

      case EntitySources.tuya:
        await TuyaBridgeService.instance.setEntityValue(
          device: device,
          entityKey: key,
          value: value,
        );
        return;

      default:
        throw UnsupportedError('${entity.source} is read-only in this build.');
    }
  }

  LocalHttpDevice _findConfig(RustlerEntity entity) {
    final String prefix = switch (entity.source) {
      EntitySources.sonoff => 'sonoff.',
      EntitySources.esp => 'esp.',
      EntitySources.tuya => 'tuya.',
      _ => '',
    };

    if (prefix.isEmpty || !entity.id.startsWith(prefix)) {
      throw StateError('Unable to resolve local device for ${entity.id}.');
    }

    final String remainder = entity.id.substring(prefix.length);
    final String configId = remainder.split('.').first;

    for (final LocalHttpDevice device in _configs.devices.value) {
      if (device.id == configId) return device;
    }

    throw StateError('Local device config "$configId" was not found.');
  }

  String _entityKey(RustlerEntity entity, LocalHttpDevice device) {
    final String prefix = '${entity.source}.${device.id}.';
    if (!entity.id.startsWith(prefix)) return entity.id;
    return entity.id.substring(prefix.length);
  }
}
