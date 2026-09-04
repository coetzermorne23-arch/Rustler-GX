import '../../models/rustler_entity.dart';

class GenericJsonEntityMapper {
  const GenericJsonEntityMapper();

  List<RustlerEntity> map({
    required String deviceId,
    required String source,
    required Map<String, dynamic> data,
    DateTime? updatedAt,
  }) {
    final DateTime timestamp = updatedAt ?? DateTime.now();
    final List<RustlerEntity> entities = <RustlerEntity>[];

    void walk(String prefix, dynamic value) {
      if (value is Map) {
        for (final MapEntry<dynamic, dynamic> entry in value.entries) {
          final String key = _slug(entry.key.toString());
          if (key.isEmpty) continue;
          walk(prefix.isEmpty ? key : '$prefix.$key', entry.value);
        }
        return;
      }

      if (value is List) {
        for (int index = 0; index < value.length; index++) {
          walk(prefix.isEmpty ? '$index' : '$prefix.$index', value[index]);
        }
        return;
      }

      if (value is num || value is bool || value is String) {
        final String safePrefix = prefix.isEmpty ? 'value' : prefix;
        entities.add(
          RustlerEntity(
            id: '$source.$deviceId.$safePrefix',
            name: _title(safePrefix.split('.').last),
            type: _typeFor(safePrefix, value),
            value: value,
            unit: _unitFor(safePrefix),
            source: source,
            available: true,
            updatedAt: timestamp,
          ),
        );
      }
    }

    walk('', data);
    return entities;
  }

  RustlerEntityType _typeFor(String key, dynamic value) {
    final String lower = key.toLowerCase();

    if (_containsAny(lower, <String>['latitude', 'longitude', 'gps'])) {
      return RustlerEntityType.gps;
    }
    if (_containsAny(lower, <String>['relay'])) {
      return RustlerEntityType.relay;
    }
    if (value is bool ||
        _containsAny(lower, <String>['switch', 'enabled', 'active', 'on'])) {
      return RustlerEntityType.binarySensor;
    }
    if (_containsAny(lower, <String>['soc', 'battery', 'voltage'])) {
      return RustlerEntityType.battery;
    }
    if (_containsAny(lower, <String>['tank', 'level'])) {
      return RustlerEntityType.tank;
    }
    if (_containsAny(
      lower,
      <String>['temp', 'humidity', 'pressure', 'climate'],
    )) {
      return RustlerEntityType.climate;
    }
    if (value is num) {
      return RustlerEntityType.number;
    }
    return RustlerEntityType.sensor;
  }

  String? _unitFor(String key) {
    final String lower = key.toLowerCase();

    if (_containsAny(lower, <String>['temperature', 'temp_c', 'temp'])) {
      return '°C';
    }
    if (_containsAny(lower, <String>['voltage', 'volt'])) return 'V';
    if (_containsAny(lower, <String>['current', 'amps', 'amp'])) return 'A';
    if (_containsAny(lower, <String>['power', 'watts', 'watt'])) return 'W';
    if (_containsAny(lower, <String>['soc', 'percent', 'humidity'])) return '%';
    if (_containsAny(lower, <String>['energy_kwh', 'yield'])) return 'kWh';
    if (_containsAny(lower, <String>['frequency', 'hz'])) return 'Hz';
    if (_containsAny(lower, <String>['rpm'])) return 'rpm';
    return null;
  }

  bool _containsAny(String value, List<String> needles) {
    return needles.any(value.contains);
  }

  String _slug(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  String _title(String value) {
    final String spaced = value.replaceAll('_', ' ');
    if (spaced.isEmpty) return 'Value';
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}
